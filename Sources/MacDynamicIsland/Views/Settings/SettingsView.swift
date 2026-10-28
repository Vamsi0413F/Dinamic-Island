import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var permissions: PermissionManager
    @EnvironmentObject var stateManager: IslandStateManager
    
    @State private var showingResetAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(settingsStore.accentColor)
                Text("Dynamic Island Settings")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    withAnimation {
                        stateManager.activeWidget = .media
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(settingsStore.accentColor)
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 14) {
                    // Geometry Section
                    let notchInfo = ScreenNotchDetector.shared.detectNotch()
                    settingsSection("Notch & Display Calibration (\(DeviceHardwareInfo.shared.displayModelName))") {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Display")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(notchInfo.screenName) (\(Int(notchInfo.screenFrame.width))×\(Int(notchInfo.screenFrame.height)) @ \(Int(notchInfo.scaleFactor))x)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            HStack {
                                Text("Detected Hardware Notch")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(notchInfo.hasNotch
                                     ? String(format: "%.1f pt × %.1f pt", notchInfo.notchWidth, notchInfo.notchHeight)
                                     : "None (Floating Pill)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(notchInfo.hasNotch ? .green : .cyan)
                            }
                            
                            Divider().background(Color.white.opacity(0.08))
                            
                            sliderRow(title: "Width Fine-Tuning", value: $settingsStore.notchWidthOffset, range: -30...30, unit: "pt")
                            sliderRow(title: "Height Fine-Tuning", value: $settingsStore.notchHeightOffset, range: -10...20, unit: "pt")
                            sliderRow(title: "Corner Radius", value: $settingsStore.notchCornerRadius, range: 12...28, unit: "pt")
                            sliderRow(title: "Vertical Offset", value: $settingsStore.notchYOffset, range: -10...20, unit: "pt")
                            
                            Toggle("Prefer Built-in Notch Screen", isOn: $settingsStore.preferBuiltInNotchDisplay)
                                .toggleStyle(.switch)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Behavior Section
                    settingsSection("Interaction & Animations") {
                        VStack(spacing: 8) {
                            Toggle("Hover to Expand", isOn: $settingsStore.hoverToExpand)
                                .toggleStyle(.switch)
                                .foregroundColor(.white)
                            
                            if settingsStore.hoverToExpand {
                                sliderRow(title: "Hover Delay", value: $settingsStore.hoverExpandDelay, range: 0.1...1.0, unit: "s")
                            }
                            
                            sliderRow(title: "Auto-Collapse Delay", value: $settingsStore.autoCollapseSeconds, range: 1.5...10.0, unit: "s")
                            
                            Toggle("Reduce Motion", isOn: $settingsStore.reduceMotion)
                                .toggleStyle(.switch)
                                .foregroundColor(.white)
                            
                            Toggle("Show Music Waveform", isOn: $settingsStore.showMusicVisualizer)
                                .toggleStyle(.switch)
                                .foregroundColor(.white)
                            
                            Toggle("Launch at Login", isOn: $settingsStore.launchAtLogin)
                                .toggleStyle(.switch)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Permissions Section
                    settingsSection("Permissions & System Access") {
                        VStack(spacing: 6) {
                            permissionRow(name: "Camera (Mirror Preview)", isGranted: permissions.hasCameraPermission, pane: "Camera")
                            permissionRow(name: "Calendar (Today's Events)", isGranted: permissions.hasCalendarPermission, pane: "Calendars")
                            permissionRow(name: "Accessibility", isGranted: permissions.isAccessibilityTrusted, pane: "Accessibility")
                        }
                    }
                    
                    // Reset Button
                    Button("Reset All Settings to Defaults") {
                        showingResetAlert = true
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.top, 6)
                    .buttonStyle(.plain)
                    .alert("Reset Settings?", isPresented: $showingResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) {
                            settingsStore.resetToDefaults()
                        }
                    } message: {
                        Text("This will restore default notch dimensions and behavior.")
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 250)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
            
            content()
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    @ViewBuilder
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(String(format: unit == "s" ? "%.2f %@" : "%.0f %@", value.wrappedValue, unit))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            
            Slider(value: value, in: range)
                .frame(width: 120)
        }
    }
    
    @ViewBuilder
    private func permissionRow(name: String, isGranted: Bool, pane: String) -> some View {
        HStack {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isGranted ? .green : .orange)
                .font(.system(size: 12))
            
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Button("Settings...") {
                permissions.openSystemSettingsPrivacy(pane: pane)
            }
            .font(.system(size: 10))
            .foregroundColor(settingsStore.accentColor)
            .buttonStyle(.plain)
        }
    }
}
