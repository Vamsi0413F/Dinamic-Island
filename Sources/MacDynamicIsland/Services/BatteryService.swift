import Foundation
import IOKit.ps

@MainActor
public final class BatteryService: ObservableObject {
    public static let shared = BatteryService()
    
    @Published public private(set) var level: Double = 1.0 // 0.0 - 1.0
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isPluggedIn: Bool = false
    @Published public private(set) var timeRemainingMinutes: Int? = nil
    
    private var timer: Timer?
    
    public init() {
        refresh()
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }
    
    public func refresh() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            if let current = desc[kIOPSCurrentCapacityKey as String] as? Int,
               let max = desc[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                self.level = Double(current) / Double(max)
            }
            
            if let isChargingVal = desc[kIOPSIsChargingKey as String] as? Bool {
                self.isCharging = isChargingVal
            }
            
            if let powerSourceState = desc[kIOPSPowerSourceStateKey as String] as? String {
                self.isPluggedIn = (powerSourceState == (kIOPSACPowerValue as String))
            }
            
            if let timeRemaining = desc[kIOPSTimeToEmptyKey as String] as? Int, timeRemaining > 0 {
                self.timeRemainingMinutes = timeRemaining
            } else if let timeRemaining = desc[kIOPSTimeToFullChargeKey as String] as? Int, timeRemaining > 0 {
                self.timeRemainingMinutes = timeRemaining
            } else {
                self.timeRemainingMinutes = nil
            }
            
            break
        }
    }
    
    isolated deinit {
        timer?.invalidate()
    }
}
