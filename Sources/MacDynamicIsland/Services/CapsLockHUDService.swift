import Foundation
import AppKit

@MainActor
public final class CapsLockHUDService: ObservableObject {
    public static let shared = CapsLockHUDService()
    
    @Published public private(set) var isCapsLockOn: Bool = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isInitialized = false
    
    public init() {
        self.isCapsLockOn = NSEvent.modifierFlags.contains(.capsLock)
        setupMonitors()
        self.isInitialized = true
    }
    
    private func setupMonitors() {
        // Event-driven global modifier flag monitor (zero keylogging, only checks boolean capsLock flag)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleFlagsChanged(event)
            }
        }
        
        // Local monitor when app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleFlagsChanged(event)
            }
            return event
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let current = event.modifierFlags.contains(.capsLock)
        if current != self.isCapsLockOn {
            self.isCapsLockOn = current
            if isInitialized && SettingsStore.shared.capsLockHUDEnabled {
                IslandStateManager.shared.triggerHUD(.capsLock(isOn: current))
            }
        }
    }
    
    isolated deinit {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
    }
}
