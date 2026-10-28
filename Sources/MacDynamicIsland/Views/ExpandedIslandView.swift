import SwiftUI

public struct ExpandedIslandView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var mediaService: MediaService
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var metricsService: SystemMetricsService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            if mediaService.currentTrack.isPlaying {
                mediaPlaybackContent
            } else if timerService.pomodoroIsRunning || timerService.stopwatchIsRunning || timerService.countdownIsRunning {
                activeTimerContent
            } else {
                idleDashboardContent
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(height: 86)
    }
    
    // MARK: - Media Playback Peek
    private var mediaPlaybackContent: some View {
        HStack(spacing: 12) {
            // Album Art Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [settingsStore.accentColor.opacity(0.8), .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                
                Image(systemName: "music.note")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: settingsStore.accentColor.opacity(0.35), radius: 6, x: 0, y: 3)
            
            // Track Info & Scrubber
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(mediaService.currentTrack.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(mediaService.currentTrack.playerSource)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(mediaService.currentTrack.artist)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // Mini Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(height: 3)
                        let progress = mediaService.currentTrack.duration > 0
                            ? CGFloat(mediaService.currentTrack.position / mediaService.currentTrack.duration)
                            : 0.0
                        Capsule().fill(settingsStore.accentColor).frame(width: max(3, geo.size.width * min(1.0, progress)), height: 3)
                    }
                }
                .frame(height: 4)
                .padding(.top, 2)
            }
            
            // Transport Controls & Expand
            HStack(spacing: 8) {
                Button {
                    mediaService.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    mediaService.togglePlayPause()
                } label: {
                    Image(systemName: mediaService.currentTrack.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(settingsStore.accentColor)
                }
                .buttonStyle(.plain)
                
                Button {
                    mediaService.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    stateManager.openDetailed(widget: .media)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Full Media Panel")
            }
        }
    }
    
    // MARK: - Active Timer Peek
    private var activeTimerContent: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.orange.opacity(0.85))
                    .frame(width: 46, height: 46)
                
                Image(systemName: "timer")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.orange.opacity(0.35), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(timerService.pomodoroIsRunning ? "Focus Session" : (timerService.countdownIsRunning ? "Countdown" : "Stopwatch"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Text(timerService.pomodoroIsRunning
                     ? formatSeconds(timerService.pomodoroRemainingSeconds)
                     : (timerService.countdownIsRunning ? formatSeconds(timerService.countdownRemainingSeconds) : String(format: "%.1fs", timerService.stopwatchElapsedSeconds)))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    if timerService.pomodoroIsRunning {
                        timerService.togglePomodoro()
                    } else if timerService.countdownIsRunning {
                        timerService.toggleCountdown()
                    } else {
                        timerService.toggleStopwatch()
                    }
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button {
                    stateManager.openDetailed(widget: .timer)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Idle Dashboard Peek
    private var idleDashboardContent: some View {
        HStack(spacing: 12) {
            // Hardware Badge
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text(DeviceHardwareInfo.shared.chipName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("MacBook Air")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 90, alignment: .leading)
            
            Divider().background(Color.white.opacity(0.12)).frame(height: 36)
            
            // Mini Gauges (CPU, Memory, Battery)
            HStack(spacing: 10) {
                miniGauge(title: "CPU", value: "\(Int(metricsService.metrics.cpuUsagePercent))%", percent: metricsService.metrics.cpuUsagePercent / 100.0, tint: .blue)
                miniGauge(title: "RAM", value: "\(Int(metricsService.metrics.ramPercent))%", percent: metricsService.metrics.ramPercent / 100.0, tint: .purple)
                miniGauge(title: "BAT", value: "\(Int(metricsService.metrics.batteryLevel * 100))%", percent: metricsService.metrics.batteryLevel, tint: metricsService.metrics.isCharging ? .green : settingsStore.accentColor)
            }
            
            Spacer()
            
            // 3 Quick Action Shortcuts + Expand Button
            HStack(spacing: 6) {
                quickActionButton(icon: "tray.and.arrow.down", widget: .shelf, help: "File Shelf")
                quickActionButton(icon: "doc.on.clipboard", widget: .clipboard, help: "Clipboard")
                quickActionButton(icon: "note.text", widget: .notes, help: "Quick Notes")
                
                Button {
                    stateManager.openDetailed()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Full Interactive Island")
            }
        }
    }
    
    @ViewBuilder
    private func miniGauge(title: String, value: String, percent: Double, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            ProgressView(value: min(1.0, max(0.0, percent)), total: 1.0)
                .tint(tint)
                .frame(width: 40)
                .scaleEffect(x: 1, y: 0.6, anchor: .center)
        }
    }
    
    @ViewBuilder
    private func quickActionButton(icon: String, widget: WidgetType, help: String) -> some View {
        Button {
            stateManager.openDetailed(widget: widget)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .padding(6)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
    
    private func formatSeconds(_ total: Int) -> String {
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
