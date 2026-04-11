import Foundation
import Testing
@testable import NetSpeedKit

// MARK: - LatencyMonitor Unit Tests

@Suite("LatencyMonitor")
struct LatencyMonitorTests {

    @Test("Default target is Cloudflare DNS")
    func defaultTarget() {
        let monitor = LatencyMonitor()
        #expect(monitor.targetHost == "1.1.1.1")
        #expect(monitor.targetPort == 443)
    }

    @Test("Window size is 5")
    func windowSize() {
        #expect(LatencyMonitor.windowSize == 5)
    }

    @Test("Probe timeout is 5 seconds")
    func probeTimeout() {
        #expect(LatencyMonitor.probeTimeout == 5.0)
    }

    @Test("Status enum equality")
    func statusEquality() {
        #expect(LatencyMonitor.Status.idle == .idle)
        #expect(LatencyMonitor.Status.measuring == .measuring)
        #expect(LatencyMonitor.Status.unreachable == .unreachable)
        #expect(LatencyMonitor.Status.reachable(latencyMs: 10) == .reachable(latencyMs: 10))
        #expect(LatencyMonitor.Status.reachable(latencyMs: 10) != .reachable(latencyMs: 20))
        #expect(LatencyMonitor.Status.idle != .unreachable)
    }

    @Test("Can create and stop without crashing")
    func createAndStop() {
        let monitor = LatencyMonitor()
        monitor.stop()
    }

    @Test("Can start and stop without crashing")
    func startAndStop() async throws {
        let monitor = LatencyMonitor()
        monitor.start(interval: 60)
        try await Task.sleep(for: .milliseconds(100))
        monitor.stop()
    }

    @Test("updateTarget changes host")
    func updateTarget() async throws {
        let monitor = LatencyMonitor()
        monitor.updateTarget(host: "8.8.8.8", port: 80)
        try await Task.sleep(for: .milliseconds(200))
        #expect(monitor.targetHost == "8.8.8.8")
        #expect(monitor.targetPort == 80)
    }

    @Test("Live probe returns a result", .timeLimit(.minutes(1)))
    func liveProbe() async throws {
        let monitor = LatencyMonitor()

        // Accept 1 or more confirmations since the probe fires repeatedly
        try await confirmation("Got status update", expectedCount: 1...) { confirm in
            let confirmed = confirm
            await MainActor.run {
                monitor.onStatusUpdate = { status in
                    switch status {
                    case .reachable(let ms):
                        #expect(ms > 0)
                        #expect(ms < 5000)
                        confirmed()
                    case .unreachable:
                        confirmed()
                    default:
                        break
                    }
                }
            }
            // Short interval so the probe fires quickly
            monitor.start(interval: 1)
            // Wait for the probe to complete — it should fire within a few seconds
            try await Task.sleep(for: .seconds(8))
        }

        monitor.stop()
    }
}

// MARK: - LatencyMonitor ProbeResult Tests

@Suite("LatencyMonitor.ProbeResult")
struct ProbeResultTests {

    @Test("ProbeResult stores values correctly")
    func probeResultValues() {
        let now = Date()
        let result = LatencyMonitor.ProbeResult(rttMs: 42.5, timestamp: now)
        #expect(result.rttMs == 42.5)
        #expect(result.timestamp == now)
    }
}
