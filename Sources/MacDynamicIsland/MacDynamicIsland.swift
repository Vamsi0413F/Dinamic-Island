import SwiftUI
import AppKit

@main
struct MacDynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(SettingsStore.shared)
                .environmentObject(PermissionManager.shared)
                .environmentObject(IslandStateManager.shared)
                .environmentObject(SystemMetricsService.shared)
        }
    }
}
