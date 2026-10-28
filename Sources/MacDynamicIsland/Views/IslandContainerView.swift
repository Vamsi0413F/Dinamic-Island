import SwiftUI
import UniformTypeIdentifiers

public struct IslandContainerView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var shelfService: FileShelfService
    @EnvironmentObject var mediaService: MediaService
    
    @State private var isShelfDragTargeted: Bool = false
    
    public init() {}
    
    private var notchInfo: ScreenNotchInfo {
        ScreenNotchDetector.shared.detectNotch()
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Background capsule
            islandBackgroundShape
                .fill(Color.black.opacity(settingsStore.islandOpacity))
                .overlay(
                    islandBackgroundShape
                        .strokeBorder(
                            isShelfDragTargeted
                            ? settingsStore.accentColor
                            : Color.white.opacity(0.12),
                            lineWidth: isShelfDragTargeted ? 2.0 : 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 6)
            
            // Content according to active presentation mode
            VStack(spacing: 0) {
                switch stateManager.mode {
                case .compact:
                    CompactIslandView()
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    
                case .hud(let event):
                    IslandHUDView(event: event)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                case .expanded:
                    ExpandedIslandView()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                case .detailed:
                    detailedContent
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .clipShape(islandBackgroundShape)
        .onHover { isHovering in
            stateManager.handleHover(isHovering: isHovering)
        }
        .onDrop(of: [.fileURL], isTargeted: $isShelfDragTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            shelfService.addURLs([url])
                            stateManager.openDetailed(widget: .shelf)
                        }
                    }
                }
            }
            return true
        }
        .animation(
            settingsStore.reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.82),
            value: stateManager.mode
        )
    }
    
    @ViewBuilder
    private var detailedContent: some View {
        VStack(spacing: 0) {
            WidgetTabBarView()
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            
            // Active Tab View
            Group {
                switch stateManager.activeWidget {
                case .media:
                    MediaWidgetView()
                case .system:
                    SystemWidgetView()
                case .shelf:
                    ShelfWidgetView()
                case .clipboard:
                    ClipboardWidgetView()
                case .timer:
                    TimerWidgetView()
                case .notes:
                    NotesWidgetView()
                case .calendar:
                    CalendarWidgetView()
                case .tools:
                    VisualToolsWidgetView()
                }
            }
            .frame(maxHeight: .infinity)
            
            // Bottom Status Bar
            HStack {
                Button {
                    SettingsWindowController.shared.showSettings()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10))
                        Text("Settings")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(DeviceHardwareInfo.shared.chipName)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .padding(.top, 2)
        }
    }
    
    // Smooth custom shape:
    // If the screen has a physical camera notch, the top edge stays flat (0 radius)
    // so it merges seamlessly with the top display bezel without awkward gaps!
    private var islandBackgroundShape: UnevenRoundedRectangle {
        let bottomRadius = CGFloat(settingsStore.notchCornerRadius)
        let isTopFlat = notchInfo.hasNotch && (stateManager.mode == .compact || isHUDMode)
        let topRadius: CGFloat = isTopFlat ? 0 : ((stateManager.mode == .compact || isHUDMode) ? bottomRadius : 18)
        
        return UnevenRoundedRectangle(
            topLeadingRadius: topRadius,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: topRadius,
            style: .continuous
        )
    }
    
    private var isHUDMode: Bool {
        if case .hud = stateManager.mode { return true }
        return false
    }
}
