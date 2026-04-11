import Foundation
import Testing
@testable import NetSpeedKit

// MARK: - TrafficSnapshot Delta Tests

@Suite("TrafficSnapshot Delta")
struct TrafficSnapshotDeltaTests {

    @Test("Basic delta between two snapshots")
    func basicDelta() {
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 1000, sentBytes: 500)
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 2000, sentBytes: 800)
            ]
        )
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 1000)
        #expect(delta.sentBytes == 300)
    }

    @Test("Delta with multiple interfaces sums correctly")
    func multiInterfaceDelta() {
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 100, sentBytes: 50),
                "en1": InterfaceTrafficCounters(receivedBytes: 200, sentBytes: 100),
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 300, sentBytes: 150),
                "en1": InterfaceTrafficCounters(receivedBytes: 500, sentBytes: 300),
            ]
        )
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 500)  // (300-100) + (500-200)
        #expect(delta.sentBytes == 300)      // (150-50) + (300-100)
    }

    @Test("UInt32 wrapping subtraction handles rollover")
    func uint32Rollover() {
        // Simulates counter rolling from near-max to small value
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: UInt32.max - 100, sentBytes: UInt32.max - 50)
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 200, sentBytes: 100)
            ]
        )
        let delta = curr.delta(since: prev)
        // &- wrapping: 200 &- (UInt32.max - 100) = 301
        #expect(delta.receivedBytes == 301)
        #expect(delta.sentBytes == 151)
    }

    @Test("Delta ignores interfaces missing from previous snapshot")
    func newInterfaceIgnored() {
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 100, sentBytes: 50)
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 200, sentBytes: 100),
                "en1": InterfaceTrafficCounters(receivedBytes: 999, sentBytes: 999),
            ]
        )
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 100)  // only en0
        #expect(delta.sentBytes == 50)
    }

    @Test("Delta ignores interfaces missing from current snapshot")
    func disappearedInterface() {
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 100, sentBytes: 50),
                "en1": InterfaceTrafficCounters(receivedBytes: 200, sentBytes: 100),
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 300, sentBytes: 150)
            ]
        )
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 200)
        #expect(delta.sentBytes == 100)
    }

    @Test("Delta with empty snapshots returns zero")
    func emptySnapshots() {
        let prev = TrafficSnapshot(timestamp: Date(), interfaceCounters: [:])
        let curr = TrafficSnapshot(timestamp: Date(), interfaceCounters: [:])
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 0)
        #expect(delta.sentBytes == 0)
    }

    @Test("Delta with identical counters returns zero")
    func identicalCounters() {
        let counters: [String: InterfaceTrafficCounters] = [
            "en0": InterfaceTrafficCounters(receivedBytes: 12345, sentBytes: 67890)
        ]
        let prev = TrafficSnapshot(timestamp: Date(timeIntervalSince1970: 0), interfaceCounters: counters)
        let curr = TrafficSnapshot(timestamp: Date(timeIntervalSince1970: 1), interfaceCounters: counters)
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 0)
        #expect(delta.sentBytes == 0)
    }

    @Test("Rollover from exactly UInt32.max to 0")
    func exactRollover() {
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: UInt32.max, sentBytes: UInt32.max)
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 0, sentBytes: 0)
            ]
        )
        let delta = curr.delta(since: prev)
        #expect(delta.receivedBytes == 1)
        #expect(delta.sentBytes == 1)
    }

    @Test("Large rollover — counter wraps multiple GB")
    func largeRollover() {
        let prev = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: UInt32.max - 1_000_000_000, sentBytes: 0)
            ]
        )
        let curr = TrafficSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            interfaceCounters: [
                "en0": InterfaceTrafficCounters(receivedBytes: 500_000_000, sentBytes: 100)
            ]
        )
        let delta = curr.delta(since: prev)
        // Wrapping: 500_000_000 &- (UInt32.max - 1_000_000_000) = 1_500_000_001
        #expect(delta.receivedBytes == 1_500_000_001)
        #expect(delta.sentBytes == 100)
    }
}

// MARK: - Interface Filter Tests

@Suite("Interface Filtering")
struct InterfaceFilterTests {

    @Test("en0 is a measured interface")
    func en0Measured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("en0") == true)
    }

    @Test("en1 is a measured interface")
    func en1Measured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("en1") == true)
    }

    @Test("pdp_ip0 is a measured interface")
    func pdpIp0Measured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("pdp_ip0") == true)
    }

    @Test("utun0 is NOT a measured interface")
    func utunNotMeasured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("utun0") == false)
    }

    @Test("bridge0 is NOT a measured interface")
    func bridgeNotMeasured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("bridge0") == false)
    }

    @Test("llw0 is NOT a measured interface")
    func llwNotMeasured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("llw0") == false)
    }

    @Test("lo0 is NOT a measured interface")
    func loopbackNotMeasured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("lo0") == false)
    }

    @Test("awdl0 is NOT a measured interface")
    func awdlNotMeasured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("awdl0") == false)
    }

    @Test("Empty string is NOT a measured interface")
    func emptyNotMeasured() {
        #expect(NetworkTrafficReader.isMeasuredInterface("") == false)
    }
}

// MARK: - NetworkTrafficReader Live Tests

@Suite("NetworkTrafficReader Live")
struct NetworkTrafficReaderLiveTests {

    @Test("readSnapshot returns non-nil on a real machine")
    func readSnapshotReturnsData() {
        let reader = NetworkTrafficReader()
        let snapshot = reader.readSnapshot()
        #expect(snapshot != nil)
    }

    @Test("readSnapshot has a recent timestamp")
    func snapshotTimestamp() {
        let reader = NetworkTrafficReader()
        let before = Date()
        guard let snapshot = reader.readSnapshot() else {
            Issue.record("readSnapshot returned nil")
            return
        }
        let after = Date()
        #expect(snapshot.timestamp >= before)
        #expect(snapshot.timestamp <= after)
    }

    @Test("readSnapshot only returns en*/pdp_ip* interfaces")
    func onlyMeasuredInterfaces() {
        let reader = NetworkTrafficReader()
        guard let snapshot = reader.readSnapshot() else {
            Issue.record("readSnapshot returned nil")
            return
        }
        for name in snapshot.interfaceCounters.keys {
            #expect(
                NetworkTrafficReader.isMeasuredInterface(name),
                "Unexpected interface: \(name)"
            )
        }
    }
}
