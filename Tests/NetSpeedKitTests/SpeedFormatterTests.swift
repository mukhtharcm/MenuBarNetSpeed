import Foundation
import Testing
@testable import NetSpeedKit

// MARK: - Speed Format (Bytes)

@Suite("SpeedFormatter — Bytes")
struct SpeedFormatBytesTests {

    @Test("Zero bytes")
    func zeroBytes() {
        let result = SpeedFormatter.format(bytesPerSecond: 0, asBits: false)
        #expect(result.hasSuffix("/s"))
        // ByteCountFormatter uses "Zero KB" for 0
        #expect(result.contains("KB"))
    }

    @Test("Kilobytes range")
    func kilobytesRange() {
        let result = SpeedFormatter.format(bytesPerSecond: 50_000, asBits: false)
        #expect(result.contains("KB/s"))
    }

    @Test("Megabytes range")
    func megabytesRange() {
        let result = SpeedFormatter.format(bytesPerSecond: 5_000_000, asBits: false)
        #expect(result.contains("MB/s"))
    }

    @Test("Gigabytes range")
    func gigabytesRange() {
        let result = SpeedFormatter.format(bytesPerSecond: 5_000_000_000, asBits: false)
        #expect(result.contains("GB/s"))
    }

    @Test("Exact 1 KB")
    func exactOneKB() {
        let result = SpeedFormatter.format(bytesPerSecond: 1024, asBits: false)
        #expect(result.contains("1"))
        #expect(result.contains("KB/s"))
    }
}

// MARK: - Speed Format (Bits)

@Suite("SpeedFormatter — Bits")
struct SpeedFormatBitsTests {

    @Test("Zero bits")
    func zeroBits() {
        let result = SpeedFormatter.formatBits(bytesPerSecond: 0)
        #expect(result == "0 bps")
    }

    @Test("Small value stays in bps")
    func smallBps() {
        let result = SpeedFormatter.formatBits(bytesPerSecond: 10)
        #expect(result == "80 bps")
    }

    @Test("Kbps range")
    func kbpsRange() {
        let result = SpeedFormatter.formatBits(bytesPerSecond: 1000)
        #expect(result.contains("Kbps"))
    }

    @Test("Mbps range")
    func mbpsRange() {
        // 10 MB/s = 80 Mbps
        let result = SpeedFormatter.formatBits(bytesPerSecond: 10_000_000)
        #expect(result.contains("Mbps"))
    }

    @Test("Gbps range")
    func gbpsRange() {
        // 1 GB/s = 8 Gbps
        let result = SpeedFormatter.formatBits(bytesPerSecond: 1_000_000_000)
        #expect(result.contains("Gbps"))
    }

    @Test("Precision: >= 100 shows 0 decimal places")
    func precisionLargeValue() {
        // 15_000_000 bytes/s = 120 Mbps → should show "120 Mbps"
        let result = SpeedFormatter.formatBits(bytesPerSecond: 15_000_000)
        #expect(result == "120 Mbps")
    }

    @Test("Precision: 10-99 shows 1 decimal place")
    func precisionMediumValue() {
        // 5_000_000 bytes/s = 40 Mbps → should show "40.0 Mbps"
        let result = SpeedFormatter.formatBits(bytesPerSecond: 5_000_000)
        #expect(result == "40.0 Mbps")
    }

    @Test("Precision: < 10 shows 2 decimal places")
    func precisionSmallValue() {
        // 500_000 bytes/s = 4 Mbps → should show "4.00 Mbps"
        let result = SpeedFormatter.formatBits(bytesPerSecond: 500_000)
        #expect(result == "4.00 Mbps")
    }
}

// MARK: - Compact Format (Bytes)

@Suite("SpeedFormatter — Compact Bytes")
struct CompactFormatBytesTests {

    @Test("Zero bytes compact")
    func zeroCompact() {
        #expect(SpeedFormatter.compactFormat(bytesPerSecond: 0) == "0B/s")
    }

    @Test("Sub-KB stays in bytes")
    func subKB() {
        #expect(SpeedFormatter.compactFormat(bytesPerSecond: 500) == "500B/s")
    }

    @Test("KB range")
    func kbRange() {
        let result = SpeedFormatter.compactFormat(bytesPerSecond: 50_000)
        #expect(result.contains("KB/s"))
    }

    @Test("MB range")
    func mbRange() {
        let result = SpeedFormatter.compactFormat(bytesPerSecond: 5_000_000)
        #expect(result.contains("MB/s"))
    }

    @Test("GB range")
    func gbRange() {
        let result = SpeedFormatter.compactFormat(bytesPerSecond: 5_000_000_000)
        #expect(result.contains("GB/s"))
    }

    @Test("1023 bytes stays in B/s")
    func justUnderKB() {
        #expect(SpeedFormatter.compactFormat(bytesPerSecond: 1023) == "1023B/s")
    }

    @Test("1024 bytes becomes KB/s")
    func exactKB() {
        let result = SpeedFormatter.compactFormat(bytesPerSecond: 1024)
        #expect(result.contains("KB/s"))
    }
}

// MARK: - Compact Format (Bits)

@Suite("SpeedFormatter — Compact Bits")
struct CompactFormatBitsTests {

    @Test("Zero compact bits")
    func zeroCompactBits() {
        #expect(SpeedFormatter.compactFormatBits(bytesPerSecond: 0) == "0bps")
    }

    @Test("Small value stays in bps")
    func smallCompactBps() {
        #expect(SpeedFormatter.compactFormatBits(bytesPerSecond: 10) == "80bps")
    }

    @Test("Kb range")
    func kbRange() {
        let result = SpeedFormatter.compactFormatBits(bytesPerSecond: 1000)
        #expect(result.contains("Kb"))
    }

    @Test("Mb range")
    func mbRange() {
        let result = SpeedFormatter.compactFormatBits(bytesPerSecond: 5_000_000)
        #expect(result.contains("Mb"))
    }
}

// MARK: - Byte Count Formatting

@Suite("SpeedFormatter — Byte Count")
struct ByteCountFormattingTests {

    @Test("Zero bytes")
    func zeroByteCount() {
        let result = SpeedFormatter.formatByteCount(0)
        // ByteCountFormatter uses "Zero KB" for 0
        #expect(result.contains("KB"))
    }

    @Test("Large byte count")
    func largeByteCount() {
        let result = SpeedFormatter.formatByteCount(1_073_741_824)  // 1 GB
        #expect(result.contains("GB"))
    }

    @Test("UInt64 max doesn't crash")
    func uint64MaxByteCount() {
        // Should not crash — Int64(clamping:) clamps to Int64.max
        let result = SpeedFormatter.formatByteCount(UInt64.max)
        #expect(!result.isEmpty)
    }
}

// MARK: - Latency Formatting

@Suite("SpeedFormatter — Latency")
struct LatencyFormattingTests {

    @Test("Sub-millisecond shows <1 ms")
    func subMs() {
        #expect(SpeedFormatter.formatLatency(0.5) == "<1 ms")
    }

    @Test("1-10ms shows one decimal")
    func lowMs() {
        #expect(SpeedFormatter.formatLatency(5.3) == "5.3 ms")
    }

    @Test(">=10ms shows integer")
    func normalMs() {
        #expect(SpeedFormatter.formatLatency(42.7) == "43 ms")
    }

    @Test("Exactly 10ms")
    func exactly10() {
        #expect(SpeedFormatter.formatLatency(10.0) == "10 ms")
    }

    @Test("Very high latency")
    func highLatency() {
        #expect(SpeedFormatter.formatLatency(1500.0) == "1500 ms")
    }

    @Test("Zero latency shows <1 ms")
    func zeroLatency() {
        #expect(SpeedFormatter.formatLatency(0.0) == "<1 ms")
    }
}

// MARK: - Compact Latency

@Suite("SpeedFormatter — Compact Latency")
struct CompactLatencyTests {

    @Test("Nil shows em dash")
    func nilLatency() {
        #expect(SpeedFormatter.compactLatency(nil) == "—")
    }

    @Test("Sub-ms compact")
    func subMsCompact() {
        #expect(SpeedFormatter.compactLatency(0.3) == "<1ms")
    }

    @Test("Normal compact")
    func normalCompact() {
        let result = SpeedFormatter.compactLatency(42.7)
        #expect(result == "43ms")
    }

    @Test("Low ms compact")
    func lowMsCompact() {
        let result = SpeedFormatter.compactLatency(5.3)
        #expect(result == "5ms")
    }
}

// MARK: - Threshold Check

@Suite("SpeedFormatter — Threshold")
struct ThresholdCheckTests {

    @Test("No threshold exceeded returns nil")
    func belowThreshold() {
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: 500_000,
            uploadBytesPerSecond: 200_000,
            thresholdMBps: 10.0
        )
        #expect(result == nil)
    }

    @Test("Download exceeds threshold")
    func downloadExceeds() {
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: 20_000_000,
            uploadBytesPerSecond: 100_000,
            thresholdMBps: 10.0
        )
        #expect(result != nil)
        #expect(result?.direction == "Download")
        #expect(result?.speed == 20_000_000)
    }

    @Test("Upload exceeds threshold")
    func uploadExceeds() {
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: 100_000,
            uploadBytesPerSecond: 20_000_000,
            thresholdMBps: 10.0
        )
        #expect(result != nil)
        #expect(result?.direction == "Upload")
    }

    @Test("Both exceed — download takes priority")
    func bothExceed() {
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: 20_000_000,
            uploadBytesPerSecond: 20_000_000,
            thresholdMBps: 10.0
        )
        #expect(result?.direction == "Download")
    }

    @Test("Zero threshold returns nil")
    func zeroThreshold() {
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: 20_000_000,
            uploadBytesPerSecond: 20_000_000,
            thresholdMBps: 0.0
        )
        #expect(result == nil)
    }

    @Test("Exactly at threshold — not exceeded")
    func exactlyAtThreshold() {
        let thresholdBytes = UInt64(10.0 * 1024 * 1024)
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: thresholdBytes,
            uploadBytesPerSecond: 0,
            thresholdMBps: 10.0
        )
        #expect(result == nil)  // Must be > not >=
    }

    @Test("One byte over threshold — exceeded")
    func oneByteOverThreshold() {
        let thresholdBytes = UInt64(10.0 * 1024 * 1024)
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: thresholdBytes + 1,
            uploadBytesPerSecond: 0,
            thresholdMBps: 10.0
        )
        #expect(result != nil)
        #expect(result?.direction == "Download")
    }

    @Test("Negative-ish threshold (very small) returns nil")
    func tinyThreshold() {
        // 0.0001 MB/s ≈ 104 bytes
        let result = SpeedFormatter.checkThreshold(
            downloadBytesPerSecond: 50,
            uploadBytesPerSecond: 50,
            thresholdMBps: 0.0001
        )
        #expect(result == nil)
    }
}
