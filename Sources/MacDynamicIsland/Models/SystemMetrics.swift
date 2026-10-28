import Foundation

public struct SystemMetrics: Equatable, Sendable {
    public var cpuUsagePercent: Double = 0.0 // 0.0 - 100.0%
    public var ramUsedBytes: UInt64 = 0
    public var ramTotalBytes: UInt64 = 0
    public var diskUsedBytes: UInt64 = 0
    public var diskTotalBytes: UInt64 = 0
    public var networkUploadBytesPerSec: Double = 0
    public var networkDownloadBytesPerSec: Double = 0
    public var batteryLevel: Double = 1.0 // 0.0 - 1.0
    public var isCharging: Bool = false
    public var timeRemainingMinutes: Int? = nil
    public var isCapsLockOn: Bool = false
    public var wifiSSID: String = "Connected"
    
    public init() {}
    
    public var ramPercent: Double {
        guard ramTotalBytes > 0 else { return 0.0 }
        return Double(ramUsedBytes) / Double(ramTotalBytes) * 100.0
    }
    
    public var diskPercent: Double {
        guard diskTotalBytes > 0 else { return 0.0 }
        return Double(diskUsedBytes) / Double(diskTotalBytes) * 100.0
    }
    
    public var formattedRAM: String {
        let used = ByteCountFormatter.string(fromByteCount: Int64(ramUsedBytes), countStyle: .memory)
        let total = ByteCountFormatter.string(fromByteCount: Int64(ramTotalBytes), countStyle: .memory)
        return "\(used) / \(total)"
    }
    
    public var formattedDisk: String {
        let free = ByteCountFormatter.string(fromByteCount: Int64(diskTotalBytes - diskUsedBytes), countStyle: .file)
        return "\(free) free"
    }
}
