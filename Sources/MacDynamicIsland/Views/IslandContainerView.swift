import SwiftUI
import UniformTypeIdentifiers

public struct IslandContainerView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var shelfService: FileShelfService
    @EnvironmentObject var mediaService: MediaService
    
    @State private var isShelfDragTargeted: Bool = false
    @State private var showingSettings: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Background Pill
            RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                .fill(Color.black.opacity(settingsStore.islandOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                        .strokeBorder(
                            isShelfDragTargeted
                            ? settingsStore.accentColor
                            : Color.white.opacity(0.14),
                            lineWidth: isShelfDragTargeted ? 2.0 : 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8)
            
            // Content
            VStack(spacing: 0) {
                switch stateManager.mode {
                case .compact:
                    CompactIslandView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    
                case .expanded:
                    ExpandedIslandView()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                case .detailed:
                    detailedContent
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous))
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
            settingsStore.reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.82),
            value: stateManager.mode
        )
    }
    
    @ViewBuilder
    private var detailedContent: some View {
        VStack(spacing: 0) {
            WidgetTabBarView()
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            
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
            
            // Bottom Status / Settings Bar
            HStack {
                Button {
                    showingSettings.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11))
                        Text("Calibrate / Settings")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("MacDynamicIsland")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .frame(width: 440, height: 340)
                .background(Color.black.opacity(0.95))
        }
    }
    
    private var islandCornerRadius: CGFloat {
        switch stateManager.mode {
        case .compact:
            return CGFloat(settingsStore.notchCornerRadius)
        case .expanded:
            return 24
        case .detailed:
            return 28
        }
    }
}
