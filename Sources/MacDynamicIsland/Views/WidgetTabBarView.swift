import SwiftUI

public struct WidgetTabBarView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 6) {
            // Widget tabs
            ForEach(WidgetType.allCases) { widget in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        stateManager.activeWidget = widget
                        stateManager.openDetailed(widget: widget)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: widget.iconName)
                            .font(.system(size: 11, weight: .semibold))
                        if stateManager.activeWidget == widget {
                            Text(widget.rawValue)
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        stateManager.activeWidget == widget
                        ? settingsStore.accentColor.opacity(0.3)
                        : Color.white.opacity(0.06)
                    )
                    .foregroundColor(
                        stateManager.activeWidget == widget
                        ? .white
                        : .white.opacity(0.65)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                stateManager.activeWidget == widget
                                ? settingsStore.accentColor.opacity(0.5)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Pin toggle
            Button {
                stateManager.isPinnedExpanded.toggle()
                if !stateManager.isPinnedExpanded {
                    stateManager.scheduleAutoCollapse()
                } else {
                    stateManager.cancelAutoCollapse()
                }
            } label: {
                Image(systemName: stateManager.isPinnedExpanded ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundColor(stateManager.isPinnedExpanded ? settingsStore.accentColor : .white.opacity(0.6))
                    .padding(5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(stateManager.isPinnedExpanded ? "Unpin Island (auto-collapses)" : "Pin Island Open")
            
            // Collapse button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    stateManager.collapse()
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Collapse Island")
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }
}
