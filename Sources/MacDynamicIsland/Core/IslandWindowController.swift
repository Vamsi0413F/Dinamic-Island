import AppKit
import SwiftUI
import Combine

@MainActor
public final class IslandWindowController: ObservableObject {
    public static let shared = IslandWindowController()
    
    public private(set) var panel: IslandPanel?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupObservers()
    }
    
    public func setupWindow() {
        let notchInfo = ScreenNotchDetector.shared.detectNotch()
        let initialRect = calculateFrame(for: .compact, notchInfo: notchInfo)
        
        let panel = IslandPanel(contentRect: initialRect)
        let containerView = IslandContainerView()
            .environmentObject(IslandStateManager.shared)
            .environmentObject(SettingsStore.shared)
            .environmentObject(MediaService.shared)
            .environmentObject(SystemMetricsService.shared)
            .environmentObject(BatteryService.shared)
            .environmentObject(TimerService.shared)
            .environmentObject(ClipboardService.shared)
            .environmentObject(FileShelfService.shared)
            .environmentObject(CalendarService.shared)
            .environmentObject(VisualToolsService.shared)
            .environmentObject(PermissionManager.shared)
        
        panel.contentView = NSHostingView(rootView: containerView)
        panel.orderFrontRegardless()
        self.panel = panel
        
        updateFrame(animated: false)
    }
    
    private func setupObservers() {
        // Observe mode changes
        IslandStateManager.shared.$mode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame(animated: true)
            }
            .store(in: &cancellables)
        
        // Observe screen configuration & wake notifications
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame(animated: false)
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame(animated: false)
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame(animated: false)
            }
            .store(in: &cancellables)
    }
    
    public func updateFrame(animated: Bool) {
        guard let panel = panel else { return }
        
        let notchInfo = ScreenNotchDetector.shared.detectNotch()
        let mode = IslandStateManager.shared.mode
        let targetFrame = calculateFrame(for: mode, notchInfo: notchInfo)
        
        if animated && !SettingsStore.shared.reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(targetFrame, display: true)
            }
        } else {
            panel.setFrame(targetFrame, display: true)
        }
    }
    
    private func calculateFrame(for mode: IslandPresentationMode, notchInfo: ScreenNotchInfo) -> NSRect {
        let screen = notchInfo.screenFrame
        let yOffset = SettingsStore.shared.notchYOffset
        
        let width: CGFloat
        let height: CGFloat
        
        switch mode {
        case .compact:
            width = max(100, notchInfo.notchWidth + SettingsStore.shared.notchWidthOffset)
            height = max(28, notchInfo.notchHeight + SettingsStore.shared.notchHeightOffset)
        case .expanded:
            width = min(460, max(360, screen.width - 40))
            height = 180
        case .detailed:
            width = min(600, max(480, screen.width - 40))
            height = min(460, max(380, screen.height - 80))
        }
        
        let x = screen.midX - (width / 2.0)
        
        // If display has a physical notch, hug the top edge. Otherwise float with a 10pt margin.
        let y: CGFloat
        if notchInfo.hasNotch {
            y = screen.maxY - height + yOffset
        } else {
            y = screen.maxY - height - 10.0 + yOffset
        }
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
