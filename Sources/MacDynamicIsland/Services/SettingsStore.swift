import Foundation
import SwiftUI
import ServiceManagement

@MainActor
public final class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()
    
    // Notch Geometry Calibration (Offsets relative to hardware detection)
    @AppStorage("notchWidthOffset") public var notchWidthOffset: Double = 0.0
    @AppStorage("notchHeightOffset") public var notchHeightOffset: Double = 0.0
    @AppStorage("notchCornerRadius") public var notchCornerRadius: Double = 18.0
    @AppStorage("notchYOffset") public var notchYOffset: Double = 0.0
    @AppStorage("preferBuiltInNotchDisplay") public var preferBuiltInNotchDisplay: Bool = true
    
    // Behavior
    @AppStorage("hoverToExpand") public var hoverToExpand: Bool = true
    @AppStorage("hoverExpandDelay") public var hoverExpandDelay: Double = 0.25
    @AppStorage("autoCollapseSeconds") public var autoCollapseSeconds: Double = 4.0
    @AppStorage("enableHaptics") public var enableHaptics: Bool = true
    @AppStorage("showMusicVisualizer") public var showMusicVisualizer: Bool = true
    @AppStorage("clipboardMonitoringEnabled") public var clipboardMonitoringEnabled: Bool = true
    @AppStorage("clipboardMaxItems") public var clipboardMaxItems: Int = 50
    @AppStorage("keepAwakeActive") public var keepAwakeActive: Bool = false
    
    // Appearance
    @AppStorage("accentColorHex") public var accentColorHex: String = "#0A84FF" // macOS system blue
    @AppStorage("islandOpacity") public var islandOpacity: Double = 0.98
    @AppStorage("reduceMotion") public var reduceMotion: Bool = false
    
    // Launch at login
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin(enabled: launchAtLogin)
        }
    }
    
    public init() {}
    
    public func resetToDefaults() {
        notchWidthOffset = 0.0
        notchHeightOffset = 0.0
        notchCornerRadius = 18.0
        notchYOffset = 0.0
        preferBuiltInNotchDisplay = true
        hoverToExpand = true
        hoverExpandDelay = 0.25
        autoCollapseSeconds = 4.0
        enableHaptics = true
        showMusicVisualizer = true
        clipboardMonitoringEnabled = true
        clipboardMaxItems = 50
        keepAwakeActive = false
        accentColorHex = "#0A84FF"
        islandOpacity = 0.98
        reduceMotion = false
        launchAtLogin = false
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[SettingsStore] LaunchAtLogin note: \(error.localizedDescription)")
        }
    }
    
    public var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") { cleanHex.removeFirst() }
        guard cleanHex.count == 6, let rgb = UInt64(cleanHex, radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
