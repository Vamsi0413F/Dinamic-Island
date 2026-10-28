import Foundation
import SwiftUI

@MainActor
public final class IslandStateManager: ObservableObject {
    public static let shared = IslandStateManager()
    
    @Published public var mode: IslandPresentationMode = .compact
    @Published public var activeWidget: WidgetType = .media
    @Published public var isHovered: Bool = false
    @Published public var isPinnedExpanded: Bool = false
    @Published public var notesContent: String = "Welcome to MacDynamicIsland!\n- Drag files directly onto the notch\n- Track CPU, RAM, & Battery\n- Pomodoro & Stopwatch built-in"
    
    private var hoverTimer: Timer?
    private var autoCollapseTimer: Timer?
    
    public init() {}
    
    public func handleHover(isHovering: Bool) {
        self.isHovered = isHovering
        hoverTimer?.invalidate()
        
        guard SettingsStore.shared.hoverToExpand, !isPinnedExpanded else { return }
        
        if isHovering {
            let delay = SettingsStore.shared.hoverExpandDelay
            hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isHovered else { return }
                    if self.mode == .compact {
                        self.mode = .expanded
                    }
                }
            }
        } else {
            // Hover ended
            scheduleAutoCollapse()
        }
    }
    
    public func expand(to widget: WidgetType? = nil) {
        if let widget = widget {
            self.activeWidget = widget
        }
        self.mode = .expanded
        scheduleAutoCollapse()
    }
    
    public func openDetailed(widget: WidgetType? = nil) {
        if let widget = widget {
            self.activeWidget = widget
        }
        self.mode = .detailed
        self.isPinnedExpanded = true
        autoCollapseTimer?.invalidate()
    }
    
    public func collapse() {
        self.isPinnedExpanded = false
        self.mode = .compact
        autoCollapseTimer?.invalidate()
        hoverTimer?.invalidate()
    }
    
    public func toggleExpanded() {
        if mode == .compact {
            mode = .expanded
            isPinnedExpanded = true
        } else {
            collapse()
        }
    }
    
    public func scheduleAutoCollapse() {
        guard !isPinnedExpanded else { return }
        autoCollapseTimer?.invalidate()
        let timeout = SettingsStore.shared.autoCollapseSeconds
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isHovered, !self.isPinnedExpanded else { return }
                self.mode = .compact
            }
        }
    }
    
    public func cancelAutoCollapse() {
        autoCollapseTimer?.invalidate()
    }
}
