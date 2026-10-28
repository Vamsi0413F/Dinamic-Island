import AppKit
import SwiftUI

public final class IslandPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
    }
    
    public override var canBecomeKey: Bool {
        // Allow becoming key when detailed so textfields (Notes, Search) work
        return IslandStateManager.shared.mode == .detailed
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}
