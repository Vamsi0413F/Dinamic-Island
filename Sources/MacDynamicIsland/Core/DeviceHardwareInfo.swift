import Foundation

public struct DeviceHardwareInfo: Sendable {
    public static let shared = DeviceHardwareInfo()
    
    public let chipName: String
    public let modelIdentifier: String
    public let modelFamily: String
    public let displayModelName: String
    public let physicalCores: Int
    public let totalMemoryBytes: UInt64
    
    public init() {
        // Query CPU brand string (e.g. "Apple M5", "Apple M2", etc.)
        var cpuSize = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &cpuSize, nil, 0)
        var cpuBuffer = [CChar](repeating: 0, count: max(1, cpuSize))
        if cpuSize > 0 {
            sysctlbyname("machdep.cpu.brand_string", &cpuBuffer, &cpuSize, nil, 0)
        }
        let cpuBytes = cpuBuffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
        let detectedChip = String(decoding: cpuBytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        self.chipName = detectedChip.isEmpty ? "Apple Silicon" : detectedChip
        
        // Query hardware model (e.g. "Mac17,3")
        var modelSize = 0
        sysctlbyname("hw.model", nil, &modelSize, nil, 0)
        var modelBuffer = [CChar](repeating: 0, count: max(1, modelSize))
        if modelSize > 0 {
            sysctlbyname("hw.model", &modelBuffer, &modelSize, nil, 0)
        }
        let modelBytes = modelBuffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
        let detectedModel = String(decoding: modelBytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        self.modelIdentifier = detectedModel.isEmpty ? "Mac" : detectedModel
        
        // Determine friendly family name
        let lowerModel = self.modelIdentifier.lowercased()
        if lowerModel.contains("macbookair") || lowerModel.hasPrefix("mac14,2") || lowerModel.hasPrefix("mac14,15") || lowerModel.hasPrefix("mac15,12") || lowerModel.hasPrefix("mac15,13") || lowerModel.hasPrefix("mac17,3") {
            self.modelFamily = "MacBook Air"
        } else if lowerModel.contains("macbookpro") || lowerModel.hasPrefix("mac14,") || lowerModel.hasPrefix("mac15,") || lowerModel.hasPrefix("mac16,") {
            self.modelFamily = "MacBook Pro"
        } else if lowerModel.contains("macmini") {
            self.modelFamily = "Mac mini"
        } else if lowerModel.contains("macstudio") {
            self.modelFamily = "Mac Studio"
        } else if lowerModel.contains("imac") {
            self.modelFamily = "iMac"
        } else {
            self.modelFamily = "Mac"
        }
        
        self.displayModelName = "\(self.modelFamily) (\(self.chipName))"
        
        // Physical cores
        var cores: Int32 = 0
        var coresSize = MemoryLayout<Int32>.size
        sysctlbyname("hw.physicalcpu", &cores, &coresSize, nil, 0)
        self.physicalCores = Int(cores > 0 ? cores : 8)
        
        // Total Memory
        var mem: UInt64 = 0
        var memSize = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &mem, &memSize, nil, 0)
        self.totalMemoryBytes = mem > 0 ? mem : (16 * 1024 * 1024 * 1024)
    }
}
