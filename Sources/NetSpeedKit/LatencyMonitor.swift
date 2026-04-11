import Foundation
import Network

/// Measures network latency by timing TCP handshakes using NWConnection.
/// No root privileges or special entitlements required.
public final class LatencyMonitor: @unchecked Sendable {
    /// Result of a single latency probe.
    public struct ProbeResult: Sendable {
        public let rttMs: Double
        public let timestamp: Date
    }

    public enum Status: Sendable, Equatable {
        case idle
        case measuring
        case reachable(latencyMs: Double)
        case unreachable
    }

    private let queue = DispatchQueue(label: "com.mukhtharcm.netspeedbar.latency")
    private var timer: DispatchSourceTimer?
    private var currentConnection: NWConnection?

    /// Rolling window of recent probes for averaging
    private var recentProbes: [ProbeResult] = []
    public static let windowSize = 5

    /// Callback fired on main queue with updated status
    public var onStatusUpdate: (@MainActor (Status) -> Void)?

    /// Default target: Cloudflare DNS — globally distributed, reliable, fast TCP accept
    public private(set) var targetHost: String = "1.1.1.1"
    public private(set) var targetPort: UInt16 = 443

    /// Timeout for each probe in seconds
    public static let probeTimeout: TimeInterval = 5.0

    public init() {}

    public func updateTarget(host: String, port: UInt16 = 443) {
        queue.async { [weak self] in
            self?.targetHost = host
            self?.targetPort = port
            self?.recentProbes.removeAll()
        }
    }

    public func start(interval: TimeInterval) {
        queue.async { [weak self] in
            self?.stopInternal()

            let timer = DispatchSource.makeTimerSource(queue: self?.queue)
            timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(500))
            timer.setEventHandler { [weak self] in
                self?.probe()
            }
            timer.resume()
            self?.timer = timer
        }
    }

    public func stop() {
        queue.async { [weak self] in
            self?.stopInternal()
        }
    }

    private func stopInternal() {
        timer?.cancel()
        timer = nil
        currentConnection?.cancel()
        currentConnection = nil
    }

    private func probe() {
        // Cancel any lingering probe
        currentConnection?.cancel()
        currentConnection = nil

        let host = NWEndpoint.Host(targetHost)
        guard let port = NWEndpoint.Port(rawValue: targetPort) else { return }

        let params = NWParameters.tcp
        params.prohibitExpensivePaths = false
        params.prohibitedInterfaceTypes = [.loopback]

        let connection = NWConnection(host: host, port: port, using: params)
        currentConnection = connection
        let start = DispatchTime.now()

        // Protected by serial `queue` — both stateUpdateHandler and the timeout
        // dispatch on the same serial queue, so no data race is possible.
        nonisolated(unsafe) var completed = false

        connection.stateUpdateHandler = { [weak self] state in
            guard let self, !completed else { return }

            switch state {
            case .ready:
                completed = true
                let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                connection.cancel()
                self.currentConnection = nil
                self.recordProbe(rttMs: elapsed)

            case .failed, .cancelled:
                completed = true
                self.currentConnection = nil
                self.reportUnreachable()

            case .waiting(let error):
                // Network is not available — report unreachable
                completed = true
                connection.cancel()
                self.currentConnection = nil
                _ = error  // suppress unused warning
                self.reportUnreachable()

            default:
                break
            }
        }

        connection.start(queue: queue)

        // Timeout guard
        queue.asyncAfter(deadline: .now() + Self.probeTimeout) { [weak self] in
            guard !completed else { return }
            completed = true
            connection.cancel()
            self?.currentConnection = nil
            self?.reportUnreachable()
        }
    }

    private func recordProbe(rttMs: Double) {
        let result = ProbeResult(rttMs: rttMs, timestamp: Date())
        recentProbes.append(result)
        if recentProbes.count > Self.windowSize {
            recentProbes.removeFirst(recentProbes.count - Self.windowSize)
        }

        let avg = recentProbes.map(\.rttMs).reduce(0, +) / Double(recentProbes.count)
        let status = Status.reachable(latencyMs: avg)
        notifyMain(status: status)
    }

    private func reportUnreachable() {
        recentProbes.removeAll()
        notifyMain(status: .unreachable)
    }

    private func notifyMain(status: Status) {
        let callback = onStatusUpdate
        Task { @MainActor in
            callback?(status)
        }
    }

    deinit {
        timer?.cancel()
        currentConnection?.cancel()
    }
}
