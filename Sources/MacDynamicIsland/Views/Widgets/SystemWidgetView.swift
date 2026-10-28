import SwiftUI

public struct SystemWidgetView: View {
    @EnvironmentObject var metricsService: SystemMetricsService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 14) {
            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // CPU Card
                metricCard(
                    title: "CPU Load",
                    value: String(format: "%.1f%%", metricsService.metrics.cpuUsagePercent),
                    icon: "cpu",
                    tint: cpuColor(metricsService.metrics.cpuUsagePercent)
                ) {
                    ProgressView(value: min(100.0, metricsService.metrics.cpuUsagePercent), total: 100.0)
                        .tint(cpuColor(metricsService.metrics.cpuUsagePercent))
                }
                
                // RAM Card
                metricCard(
                    title: "Memory",
                    value: String(format: "%.0f%%", metricsService.metrics.ramPercent),
                    icon: "memorychip",
                    tint: .purple
                ) {
                    ProgressView(value: metricsService.metrics.ramPercent, total: 100.0)
                        .tint(.purple)
                }
                
                // Disk Card
                metricCard(
                    title: "Storage",
                    value: metricsService.metrics.formattedDisk,
                    icon: "internaldrive",
                    tint: .orange
                ) {
                    ProgressView(value: metricsService.metrics.diskPercent, total: 100.0)
                        .tint(.orange)
                }
                
                // Battery Card
                metricCard(
                    title: "Battery",
                    value: String(format: "%.0f%%", metricsService.metrics.batteryLevel * 100),
                    icon: metricsService.metrics.isCharging ? "bolt.fill" : "battery.100",
                    tint: metricsService.metrics.isCharging ? .green : settingsStore.accentColor
                ) {
                    ProgressView(value: metricsService.metrics.batteryLevel, total: 1.0)
                        .tint(metricsService.metrics.isCharging ? .green : settingsStore.accentColor)
                }
            }
            
            // Network & Indicators Bar
            HStack(spacing: 16) {
                // Download
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 12))
                    Text(formatBandwidth(metricsService.metrics.networkDownloadBytesPerSec))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                // Upload
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.indigo)
                        .font(.system(size: 12))
                    Text(formatBandwidth(metricsService.metrics.networkUploadBytesPerSec))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                if metricsService.metrics.isCapsLockOn {
                    HStack(spacing: 4) {
                        Image(systemName: "capslock.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 11))
                        Text("CAPS LOCK")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func metricCard<Content: View>(
        title: String,
        value: String,
        icon: String,
        tint: Color,
        @ViewBuilder progress: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            progress()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func cpuColor(_ usage: Double) -> Color {
        if usage > 80 { return .red }
        if usage > 50 { return .orange }
        return .blue
    }
    
    private func formatBandwidth(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024))
        } else if bytesPerSec >= 1024 {
            return String(format: "%.0f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }
}
