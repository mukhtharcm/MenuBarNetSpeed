import Foundation

struct InterfaceTrafficCounters {
    let receivedBytes: UInt32
    let sentBytes: UInt32
}

struct TrafficSnapshot {
    let timestamp: Date
    let interfaceCounters: [String: InterfaceTrafficCounters]

    func delta(since previous: TrafficSnapshot) -> (receivedBytes: UInt64, sentBytes: UInt64) {
        var receivedBytes: UInt64 = 0
        var sentBytes: UInt64 = 0

        for (name, currentCounters) in interfaceCounters {
            guard let previousCounters = previous.interfaceCounters[name] else { continue }

            receivedBytes += UInt64(currentCounters.receivedBytes &- previousCounters.receivedBytes)
            sentBytes += UInt64(currentCounters.sentBytes &- previousCounters.sentBytes)
        }

        return (receivedBytes, sentBytes)
    }
}

struct NetworkTrafficReader {
    func readSnapshot() -> TrafficSnapshot? {
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfacePointer) == 0, let firstAddress = interfacePointer else {
            return nil
        }

        defer {
            freeifaddrs(interfacePointer)
        }

        var countersByInterface: [String: InterfaceTrafficCounters] = [:]

        for pointer in sequence(first: firstAddress, next: { $0.pointee.ifa_next }) {
            let flags = Int32(pointer.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            guard isUp, isRunning, !isLoopback else { continue }
            guard let address = pointer.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }
            guard let data = pointer.pointee.ifa_data?.assumingMemoryBound(to: if_data.self).pointee else {
                continue
            }

            let name = String(cString: pointer.pointee.ifa_name)
            guard Self.isMeasuredInterface(name) else { continue }

            countersByInterface[name] = InterfaceTrafficCounters(
                receivedBytes: data.ifi_ibytes,
                sentBytes: data.ifi_obytes
            )
        }

        return TrafficSnapshot(timestamp: Date(), interfaceCounters: countersByInterface)
    }

    private static func isMeasuredInterface(_ name: String) -> Bool {
        let prefixes = ["en", "pdp_ip"]
        return prefixes.contains { name.hasPrefix($0) }
    }
}
