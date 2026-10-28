import Foundation
import AppKit
import Darwin

@MainActor
public final class SystemMetricsService: ObservableObject {
    public static let shared = SystemMetricsService()
    
    @Published public private(set) var metrics = SystemMetrics()
    
    private var timer: Timer?
    private var prevCPULoad: host_cpu_load_info?
    private var prevNetIn: UInt64 = 0
    private var prevNetOut: UInt64 = 0
    private var prevNetTime: Date = Date()
    
    public init() {
        refreshAll()
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAll()
            }
        }
    }
    
    public func refreshAll() {
        updateCPU()
        updateMemory()
        updateDisk()
        updateNetwork()
        updateBattery()
        updateModifiers()
    }
    
    private func updateCPU() {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        if let prev = prevCPULoad {
            let user = Double(load.cpu_ticks.0 - prev.cpu_ticks.0)
            let system = Double(load.cpu_ticks.1 - prev.cpu_ticks.1)
            let idle = Double(load.cpu_ticks.2 - prev.cpu_ticks.2)
            let nice = Double(load.cpu_ticks.3 - prev.cpu_ticks.3)
            let total = user + system + idle + nice
            if total > 0 {
                let usage = ((user + system + nice) / total) * 100.0
                metrics.cpuUsagePercent = max(0.0, min(100.0, usage))
            }
        }
        prevCPULoad = load
    }
    
    private func updateMemory() {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = UInt64(getpagesize())
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let used = active + wired + compressed
        
        var totalRAM: UInt64 = 0
        var totalRAMSize = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &totalRAM, &totalRAMSize, nil, 0)
        
        metrics.ramUsedBytes = used
        metrics.ramTotalBytes = totalRAM > 0 ? totalRAM : (16 * 1024 * 1024 * 1024)
    }
    
    private func updateDisk() {
        var stat = statvfs()
        if statvfs("/", &stat) == 0 {
            let blockSize = UInt64(stat.f_frsize)
            let total = UInt64(stat.f_blocks) * blockSize
            let free = UInt64(stat.f_bavail) * blockSize
            metrics.diskTotalBytes = total
            metrics.diskUsedBytes = total > free ? (total - free) : 0
        }
    }
    
    private func updateNetwork() {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return }
        defer { freeifaddrs(ifap) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            // Look for Wi-Fi or primary interface (en0, en1)
            if name.hasPrefix("en"), let data = current.pointee.ifa_data {
                let ifData = data.assumingMemoryBound(to: if_data.self)
                totalIn += UInt64(ifData.pointee.ifi_ibytes)
                totalOut += UInt64(ifData.pointee.ifi_obytes)
            }
            ptr = current.pointee.ifa_next
        }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(prevNetTime)
        if elapsed > 0.5 && prevNetIn > 0 {
            let deltaIn = totalIn >= prevNetIn ? totalIn - prevNetIn : 0
            let deltaOut = totalOut >= prevNetOut ? totalOut - prevNetOut : 0
            metrics.networkDownloadBytesPerSec = Double(deltaIn) / elapsed
            metrics.networkUploadBytesPerSec = Double(deltaOut) / elapsed
        }
        
        prevNetIn = totalIn
        prevNetOut = totalOut
        prevNetTime = now
    }
    
    private func updateBattery() {
        let battery = BatteryService.shared
        metrics.batteryLevel = battery.level
        metrics.isCharging = battery.isCharging
        metrics.timeRemainingMinutes = battery.timeRemainingMinutes
    }
    
    private func updateModifiers() {
        metrics.isCapsLockOn = NSEvent.modifierFlags.contains(.capsLock)
    }
    
    isolated deinit {
        timer?.invalidate()
    }
}
