import Foundation
import CoreGraphics
import AppKit

private typealias DisplayServicesGetBrightnessFunction = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

@MainActor
public final class BrightnessHUDService: ObservableObject {
    public static let shared = BrightnessHUDService()
    
    @Published public private(set) var currentBrightness: Float = 0.5
    @Published public private(set) var isSupported: Bool = false
    
    private var getBrightnessFn: DisplayServicesGetBrightnessFunction?
    private var monitorTimer: Timer?
    private var isInitialized = false
    
    public init() {
        loadDisplayServices()
        if isSupported {
            readBrightness(suppressHUD: true)
            startMonitoring()
            isInitialized = true
        }
    }
    
    private func loadDisplayServices() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) else {
            isSupported = false
            return
        }
        if let sym = dlsym(handle, "DisplayServicesGetBrightness") {
            self.getBrightnessFn = unsafeBitCast(sym, to: DisplayServicesGetBrightnessFunction.self)
            self.isSupported = true
        } else {
            self.isSupported = false
        }
    }
    
    public func readBrightness(suppressHUD: Bool = false) {
        guard let getBrightness = getBrightnessFn else { return }
        
        let screen = ScreenNotchDetector.shared.targetScreen()
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return
        }
        
        // Only monitor built-in display brightness (external displays use DDC/CI which is vendor-specific)
        guard CGDisplayIsBuiltin(screenNumber) != 0 else { return }
        
        var val: Float = 0
        let result = getBrightness(screenNumber, &val)
        guard result == 0 else { return }
        
        let newBrightness = max(0.0, min(1.0, val))
        let delta = abs(newBrightness - self.currentBrightness)
        
        // Threshold check to avoid jitter
        if delta > 0.015 {
            self.currentBrightness = newBrightness
            if !suppressHUD && isInitialized && SettingsStore.shared.brightnessHUDEnabled {
                IslandStateManager.shared.triggerHUD(.brightness(level: newBrightness))
            }
        }
    }
    
    private func startMonitoring() {
        monitorTimer?.invalidate()
        // Sampling at a gentle 0.4s interval only when brightness HUD is enabled
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, SettingsStore.shared.brightnessHUDEnabled else { return }
                self.readBrightness(suppressHUD: false)
            }
        }
    }
    
    isolated deinit {
        monitorTimer?.invalidate()
    }
}
