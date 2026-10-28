import Foundation
import SwiftUI

@MainActor
public final class IslandStateManager: ObservableObject {
    public static let shared = IslandStateManager()
    
    @Published public var mode: IslandPresentationMode = .compact
    @Published public var activeWidget: WidgetType = .media
    @Published public var isHovered: Bool = false
    @Published public var isPinnedExpanded: Bool = false
    @Published public var activeHUD: HUDEvent? = nil
    @Published public var notesContent: String = "Quick Scratchpad Note\n- Type anything here\n- Persisted automatically"
    
    private var hoverTimer: Timer?
    private var autoCollapseTimer: Timer?
    private var hudTimer: Timer?
    
    public init() {}
    
    public func handleHover(isHovering: Bool) {
        self.isHovered = isHovering
        
        if isHovering {
            // Cancel any pending collapse when pointer returns
            autoCollapseTimer?.invalidate()
            autoCollapseTimer = nil
            
            // If currently showing a HUD, pointer hover transitions to full expanded overview
            if case .hud = mode {
                hudTimer?.invalidate()
                hudTimer = nil
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.mode = .expanded
                }
                return
            }
            
            guard SettingsStore.shared.hoverToExpand, !isPinnedExpanded else { return }
            
            hoverTimer?.invalidate()
            let delay = SettingsStore.shared.hoverExpandDelay
            hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isHovered else { return }
                    if self.mode == .compact {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            self.mode = .expanded
                        }
                    }
                }
            }
        } else {
            // Pointer left the island region
            hoverTimer?.invalidate()
            hoverTimer = nil
            
            guard !isPinnedExpanded else { return }
            scheduleAutoCollapse()
        }
    }
    
    // MARK: - HUD Trigger (Volume, Brightness, Caps Lock)
    public func triggerHUD(_ event: HUDEvent) {
        hudTimer?.invalidate()
        self.activeHUD = event
        
        if mode == .compact || isHUDMode {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                self.mode = .hud(event)
            }
        }
        
        let timeout = SettingsStore.shared.hudDismissTimeout
        hudTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    if self.isHUDMode && !self.isHovered {
                        self.mode = .compact
                    }
                    self.activeHUD = nil
                }
            }
        }
    }
    
    private var isHUDMode: Bool {
        if case .hud = mode { return true }
        return false
    }
    
    public func expand(to widget: WidgetType? = nil) {
        if let widget = widget {
            self.activeWidget = widget
        }
        hudTimer?.invalidate()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            self.mode = .expanded
        }
        scheduleAutoCollapse()
    }
    
    public func openDetailed(widget: WidgetType? = nil) {
        if let widget = widget {
            self.activeWidget = widget
        }
        self.isPinnedExpanded = true
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = nil
        hudTimer?.invalidate()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.mode = .detailed
        }
    }
    
    public func collapse() {
        self.isPinnedExpanded = false
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = nil
        hoverTimer?.invalidate()
        hoverTimer = nil
        hudTimer?.invalidate()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            self.mode = .compact
        }
    }
    
    public func toggleExpanded() {
        if mode == .compact || isHUDMode {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                mode = .expanded
            }
            scheduleAutoCollapse()
        } else {
            collapse()
        }
    }
    
    public func togglePin() {
        isPinnedExpanded.toggle()
        if isPinnedExpanded {
            autoCollapseTimer?.invalidate()
            autoCollapseTimer = nil
        } else {
            scheduleAutoCollapse()
        }
    }
    
    public func scheduleAutoCollapse() {
        guard !isPinnedExpanded else { return }
        autoCollapseTimer?.invalidate()
        let timeout = SettingsStore.shared.autoCollapseSeconds
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isHovered, !self.isPinnedExpanded else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    self.mode = .compact
                }
            }
        }
    }
    
    public func cancelAutoCollapse() {
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = nil
    }
}
