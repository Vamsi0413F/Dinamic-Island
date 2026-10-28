import AppKit
import SwiftUI

public final class IslandPanel: NSPanel {
    private var trackingArea: NSTrackingArea?
    
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
        // Sits right at the overlay / status bar level above menu bar background
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.overlayWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        self.acceptsMouseMovedEvents = true
    }
    
    // CRITICAL: Do NOT constrain the frame to visibleFrame!
    // By default, NSWindow.constrainFrameRect pushes borderless windows down by the menu bar height (37.5pt),
    // which caused the island to appear far below the notch. Returning frameRect as-is allows
    // the window to anchor directly to the top edge of the display glass.
    public override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
    
    public override var canBecomeKey: Bool {
        // Allow becoming key only when detailed so text inputs (Notes, Search) function
        return IslandStateManager.shared.mode == .detailed
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
    
    public func updateTrackingArea() {
        if let existing = trackingArea {
            contentView?.removeTrackingArea(existing)
        }
        guard let view = contentView else { return }
        let newArea = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(newArea)
        self.trackingArea = newArea
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        Task { @MainActor in
            IslandStateManager.shared.handleHover(isHovering: true)
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        // Check if mouse truly exited the window frame to prevent false exits during resizing
        let mouseLoc = NSEvent.mouseLocation
        if !self.frame.contains(mouseLoc) {
            Task { @MainActor in
                IslandStateManager.shared.handleHover(isHovering: false)
            }
        }
    }
}
