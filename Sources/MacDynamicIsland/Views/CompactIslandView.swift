import SwiftUI

public struct CompactIslandView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var mediaService: MediaService
    @EnvironmentObject var metricsService: SystemMetricsService
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    private var notchInfo: ScreenNotchInfo {
        ScreenNotchDetector.shared.detectNotch()
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Leading wing
            leadingContent
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Middle cutout spacer (only expanded when physical hardware notch is present)
            if notchInfo.hasNotch {
                Spacer()
                    .frame(width: max(0, (notchInfo.notchWidth + settingsStore.notchWidthOffset) - 80))
            } else {
                Spacer()
                    .frame(minWidth: 8, maxWidth: 20)
            }
            
            // Trailing wing
            trailingContent
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: max(28, notchInfo.notchHeight + settingsStore.notchHeightOffset))
        .contentShape(Rectangle())
        .onTapGesture {
            stateManager.toggleExpanded()
        }
    }
    
    @ViewBuilder
    private var leadingContent: some View {
        if mediaService.currentTrack.isPlaying {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(settingsStore.accentColor)
                
                Text(mediaService.currentTrack.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } else if timerService.pomodoroIsRunning {
            HStack(spacing: 5) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
                
                Text(formatSeconds(timerService.pomodoroRemainingSeconds))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
        } else if timerService.stopwatchIsRunning {
            HStack(spacing: 5) {
                Image(systemName: "stopwatch")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                
                Text(String(format: "%.1fs", timerService.stopwatchElapsedSeconds))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
        } else {
            // Idle state: CPU & Battery indicator
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f%%", metricsService.metrics.cpuUsagePercent))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        if mediaService.currentTrack.isPlaying && settingsStore.showMusicVisualizer {
            // Animated waveform
            HStack(spacing: 2) {
                ForEach(0..<mediaService.visualizerLevels.count, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(settingsStore.accentColor)
                        .frame(width: 2.5, height: max(4, 14 * mediaService.visualizerLevels[idx]))
                        .animation(.easeInOut(duration: 0.12), value: mediaService.visualizerLevels[idx])
                }
            }
        } else if metricsService.metrics.isCharging {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                Text(String(format: "%.0f%%", metricsService.metrics.batteryLevel * 100))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
        } else if metricsService.metrics.isCapsLockOn {
            HStack(spacing: 3) {
                Image(systemName: "capslock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
            }
        } else {
            // Battery pill
            HStack(spacing: 4) {
                Text(String(format: "%.0f%%", metricsService.metrics.batteryLevel * 100))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                
                Image(systemName: batteryIconName(for: metricsService.metrics.batteryLevel))
                    .font(.system(size: 11))
                    .foregroundColor(metricsService.metrics.batteryLevel < 0.2 ? .red : .white.opacity(0.85))
            }
        }
    }
    
    private func batteryIconName(for level: Double) -> String {
        if level > 0.75 { return "battery.100" }
        if level > 0.50 { return "battery.75" }
        if level > 0.25 { return "battery.50" }
        return "battery.25"
    }
    
    private func formatSeconds(_ total: Int) -> String {
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
