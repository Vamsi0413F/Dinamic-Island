import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Island Window
        IslandWindowController.shared.setupWindow()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "oval.inset.filled", accessibilityDescription: "MacDynamicIsland")
            button.toolTip = "MacDynamicIsland"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Dynamic Island", action: #selector(toggleIsland), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Pin / Unpin Island", action: #selector(togglePin), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MacDynamicIsland", action: #selector(quitApp), keyEquivalent: "q"))
        
        item.menu = menu
        self.statusItem = item
    }
    
    @objc private func toggleIsland() {
        Task { @MainActor in
            IslandStateManager.shared.toggleExpanded()
        }
    }
    
    @objc private func togglePin() {
        Task { @MainActor in
            IslandStateManager.shared.togglePin()
        }
    }
    
    @objc private func openSettings() {
        Task { @MainActor in
            SettingsWindowController.shared.showSettings()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Do NOT terminate when settings window closes; the island and status bar presence stay alive
        return false
    }
}
