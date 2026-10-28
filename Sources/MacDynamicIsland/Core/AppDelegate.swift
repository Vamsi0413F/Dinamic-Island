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
        menu.addItem(NSMenuItem(title: "Pin Island Open", action: #selector(togglePin), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Calibrate Notch & Settings...", action: #selector(openSettings), keyEquivalent: ","))
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
            IslandStateManager.shared.isPinnedExpanded.toggle()
            if IslandStateManager.shared.isPinnedExpanded {
                IslandStateManager.shared.openDetailed()
            } else {
                IslandStateManager.shared.collapse()
            }
        }
    }
    
    @objc private func openSettings() {
        Task { @MainActor in
            IslandStateManager.shared.openDetailed()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
