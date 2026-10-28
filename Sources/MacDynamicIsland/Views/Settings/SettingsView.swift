import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var permissions: PermissionManager
    @EnvironmentObject var stateManager: IslandStateManager
    
    @State private var selectedTab: Int = 0
    @State private var showingResetAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Tab Selector
            HStack(spacing: 4) {
                tabButton("General", icon: "gearshape", tag: 0)
                tabButton("Appearance", icon: "paintbrush", tag: 1)
                tabButton("Behavior", icon: "hand.tap", tag: 2)
                tabButton("Widgets", icon: "square.grid.2x2", tag: 3)
                tabButton("Permissions", icon: "lock.shield", tag: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Tab Contents
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case 0:
                        generalSection
                    case 1:
                        appearanceSection
                    case 2:
                        behaviorSection
                    case 3:
                        widgetsSection
                    case 4:
                        permissionsSection
                    default:
                        EmptyView()
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Bottom Bar with Reset to Defaults
            HStack {
                Button("Reset to Defaults...") {
                    showingResetAlert = true
                }
                .font(.system(size: 11))
                .foregroundColor(.red.opacity(0.85))
                .buttonStyle(.plain)
                .alert("Reset All Settings?", isPresented: $showingResetAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset Everything", role: .destructive) {
                        settingsStore.resetToDefaults()
                    }
                } message: {
                    Text("This restores all notch offsets, timings, and widget preferences to factory defaults.")
                }
                
                Spacer()
                
                Text(DeviceHardwareInfo.shared.displayModelName)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 540, height: 420)
    }
    
    @ViewBuilder
    private func tabButton(_ title: String, icon: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: selectedTab == tag ? .bold : .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selectedTab == tag ? Color.accentColor.opacity(0.18) : Color.clear)
            .foregroundColor(selectedTab == tag ? Color.accentColor : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox(label: Label("Startup & Lifecycle", systemImage: "power")) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Launch MacDynamicIsland at Login", isOn: $settingsStore.launchAtLogin)
                        .toggleStyle(.switch)
                    
                    Text("Runs in the background and menu bar status item across all spaces.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            GroupBox(label: Label("Display Routing", systemImage: "display")) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Prefer Built-in Screen with Camera Notch", isOn: $settingsStore.preferBuiltInNotchDisplay)
                        .toggleStyle(.switch)
                    
                    Text("When multiple monitors are connected, keep the Dynamic Island anchored to the physical camera notch. If disabled, the island will follow the active display.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            GroupBox(label: Label("Hardware Detection", systemImage: "cpu")) {
                let info = DeviceHardwareInfo.shared
                VStack(spacing: 6) {
                    infoRow("Model", value: info.modelIdentifier)
                    infoRow("Processor", value: info.chipName)
                    infoRow("Architecture", value: "Apple Silicon (ARM64)")
                    infoRow("Cores", value: "\(info.physicalCores) Physical Cores")
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            let notch = ScreenNotchDetector.shared.detectNotch()
            GroupBox(label: Label("Notch Calibration", systemImage: "camera.badge.ellipsis")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Active Display:")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text("\(notch.screenName) (\(Int(notch.screenFrame.width))×\(Int(notch.screenFrame.height)) @ \(Int(notch.scaleFactor))x)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Detected Cutout:")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text(notch.hasNotch ? String(format: "%.1f pt × %.1f pt", notch.notchWidth, notch.notchHeight) : "No Notch (Floating Mode)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(notch.hasNotch ? .green : .cyan)
                    }
                    
                    Divider()
                    
                    sliderRow(title: "Width Offset", value: $settingsStore.notchWidthOffset, range: -30...30, unit: "pt")
                    sliderRow(title: "Height Offset", value: $settingsStore.notchHeightOffset, range: -10...20, unit: "pt")
                    sliderRow(title: "Bottom Corner Radius", value: $settingsStore.notchCornerRadius, range: 8...24, unit: "pt")
                    sliderRow(title: "Vertical Y-Offset", value: $settingsStore.notchYOffset, range: -10...20, unit: "pt")
                }
                .padding(8)
            }
            
            GroupBox(label: Label("Visual Styling", systemImage: "sparkles")) {
                VStack(spacing: 10) {
                    Toggle("Reduce Motion (Instant transitions)", isOn: $settingsStore.reduceMotion)
                        .toggleStyle(.switch)
                    
                    Toggle("Show Reactive Music Waveform", isOn: $settingsStore.showMusicVisualizer)
                        .toggleStyle(.switch)
                    
                    sliderRow(title: "Island Opacity", value: $settingsStore.islandOpacity, range: 0.8...1.0, unit: "%")
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Behavior Section
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox(label: Label("Hover Interactions", systemImage: "cursorarrow.rays")) {
                VStack(spacing: 10) {
                    Toggle("Hover to Expand Island", isOn: $settingsStore.hoverToExpand)
                        .toggleStyle(.switch)
                    
                    if settingsStore.hoverToExpand {
                        sliderRow(title: "Expand Delay", value: $settingsStore.hoverExpandDelay, range: 0.05...0.50, unit: "s")
                    }
                    
                    sliderRow(title: "Auto-Collapse Delay", value: $settingsStore.autoCollapseSeconds, range: 0.2...2.0, unit: "s")
                }
                .padding(8)
            }
            
            GroupBox(label: Label("Clipboard & Power", systemImage: "doc.on.clipboard")) {
                VStack(spacing: 10) {
                    Toggle("Local Clipboard History Monitoring", isOn: $settingsStore.clipboardMonitoringEnabled)
                        .toggleStyle(.switch)
                    
                    Toggle("Keep Mac Awake (Caffeinate)", isOn: $settingsStore.keepAwakeActive)
                        .toggleStyle(.switch)
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Widgets Section
    private var widgetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select which modules appear in the detailed tab bar:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WidgetType.allCases) { widget in
                    let isEnabled = settingsStore.isWidgetEnabled(widget)
                    Button {
                        settingsStore.toggleWidget(widget)
                    } label: {
                        HStack {
                            Image(systemName: widget.iconName)
                                .foregroundColor(isEnabled ? settingsStore.accentColor : .secondary)
                                .frame(width: 20)
                            Text(widget.rawValue)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isEnabled ? .green : .secondary)
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Permissions Section
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MacDynamicIsland respects macOS sandbox & privacy controls. Permissions are requested only when features are activated.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            GroupBox(label: Label("System Permissions", systemImage: "hand.raised")) {
                VStack(spacing: 10) {
                    permissionRow(
                        name: "Camera (Mirror Preview)",
                        desc: "Quick mirror right beneath your camera notch.",
                        isGranted: permissions.hasCameraPermission,
                        pane: "Camera"
                    )
                    
                    Divider()
                    
                    permissionRow(
                        name: "Calendar (Today's Events)",
                        desc: "Displays upcoming meetings and countdowns.",
                        isGranted: permissions.hasCalendarPermission,
                        pane: "Calendars"
                    )
                    
                    Divider()
                    
                    permissionRow(
                        name: "Accessibility",
                        desc: "Optional for global shortcuts and window tracking.",
                        isGranted: permissions.isAccessibilityTrusted,
                        pane: "Accessibility"
                    )
                }
                .padding(8)
            }
        }
    }
    
    @ViewBuilder
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }
    
    @ViewBuilder
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
            Spacer()
            Text(String(format: unit == "s" ? "%.2fs" : (unit == "%" ? "%.0f%%" : "%.1f pt"), unit == "%" ? value.wrappedValue * 100 : value.wrappedValue))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
            Slider(value: value, in: range)
                .frame(width: 130)
        }
    }
    
    @ViewBuilder
    private func permissionRow(name: String, desc: String, isGranted: Bool, pane: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isGranted ? .green : .orange)
                        .font(.system(size: 12))
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(isGranted ? "Authorized" : "Configure...") {
                permissions.openSystemSettingsPrivacy(pane: pane)
            }
            .font(.system(size: 11))
            .buttonStyle(.bordered)
        }
    }
}
