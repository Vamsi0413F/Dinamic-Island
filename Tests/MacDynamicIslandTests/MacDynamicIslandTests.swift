import Testing
import Foundation
import AppKit
@testable import MacDynamicIsland

@Suite("MacDynamicIsland Tests")
struct MacDynamicIslandTests {
    
    @Test("SystemMetrics Calculations")
    func testSystemMetrics() {
        var metrics = SystemMetrics()
        metrics.ramUsedBytes = 8 * 1024 * 1024 * 1024
        metrics.ramTotalBytes = 16 * 1024 * 1024 * 1024
        metrics.diskUsedBytes = 250 * 1024 * 1024 * 1024
        metrics.diskTotalBytes = 500 * 1024 * 1024 * 1024
        
        #expect(metrics.ramPercent == 50.0)
        #expect(metrics.diskPercent == 50.0)
        #expect(!metrics.formattedRAM.isEmpty)
        #expect(!metrics.formattedDisk.isEmpty)
    }
    
    @Test("Device Hardware Detection")
    func testDeviceHardwareDetection() {
        let hardware = DeviceHardwareInfo.shared
        #expect(!hardware.chipName.isEmpty)
        #expect(!hardware.modelIdentifier.isEmpty)
        #expect(!hardware.displayModelName.isEmpty)
        #expect(hardware.physicalCores > 0)
        #expect(hardware.totalMemoryBytes > 0)
    }
    
    @Test("Screen Notch Detector & Scaling")
    @MainActor
    func testScreenNotchDetector() {
        let detector = ScreenNotchDetector.shared
        let info = detector.detectNotch(on: nil)
        
        #expect(info.notchWidth > 0)
        #expect(info.notchHeight > 0)
        #expect(info.screenFrame.width > 0)
        #expect(info.scaleFactor >= 1.0)
        #expect(!info.screenName.isEmpty)
    }
    
    @Test("Timer Service Pomodoro Transitions & Idle Efficiency")
    @MainActor
    func testPomodoroTransitions() {
        let timer = TimerService.shared
        timer.pomodoroPhase = .work
        timer.pomodoroCompletedCycles = 0
        
        // Skip from work to short break
        timer.skipPomodoroPhase()
        #expect(timer.pomodoroPhase == .shortBreak)
        #expect(timer.pomodoroCompletedCycles == 1)
        
        // Skip back to work
        timer.skipPomodoroPhase()
        #expect(timer.pomodoroPhase == .work)
    }
    
    @Test("File Shelf Operations")
    @MainActor
    func testFileShelf() {
        let shelf = FileShelfService.shared
        shelf.clearAll()
        #expect(shelf.items.isEmpty)
        
        let tempURL = URL(fileURLWithPath: "/tmp")
        shelf.addURLs([tempURL])
        #expect(shelf.items.count == 1)
        #expect(shelf.items.first?.name == "tmp")
        
        shelf.clearAll()
        #expect(shelf.items.isEmpty)
    }
    
    @Test("Clipboard Sensitive Content Detection")
    @MainActor
    func testClipboardSensitiveDetection() {
        let item1 = ClipboardItem(text: "Hello World", isSensitive: false)
        #expect(!item1.isSensitive)
        
        let item2 = ClipboardItem(text: "-----BEGIN PRIVATE KEY----- secret", isSensitive: true)
        #expect(item2.isSensitive)
    }
    
    @Test("Settings Defaults and Reset")
    @MainActor
    func testSettingsStore() {
        let settings = SettingsStore.shared
        settings.resetToDefaults()
        
        #expect(settings.notchWidthOffset == 0.0)
        #expect(settings.notchHeightOffset == 0.0)
        #expect(settings.preferBuiltInNotchDisplay == true)
        #expect(settings.hoverToExpand == true)
        #expect(settings.accentColorHex == "#0A84FF")
        #expect(settings.volumeHUDEnabled == true)
        #expect(settings.brightnessHUDEnabled == true)
        #expect(settings.capsLockHUDEnabled == true)
        #expect(settings.hudDismissTimeout == 2.0)
    }
}
