import SwiftUI

public struct ExpandedIslandView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var mediaService: MediaService
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var metricsService: SystemMetricsService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header: Notch hugging top bar
            HStack(spacing: 12) {
                // Leading Icon / Artwork
                if mediaService.currentTrack.isPlaying {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(settingsStore.accentColor.opacity(0.8))
                            .frame(width: 38, height: 38)
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaService.currentTrack.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(mediaService.currentTrack.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                } else if timerService.pomodoroIsRunning || timerService.stopwatchIsRunning {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.8))
                            .frame(width: 38, height: 38)
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timerService.pomodoroIsRunning ? "Focus Session" : "Stopwatch")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text(timerService.pomodoroIsRunning
                             ? formatSeconds(timerService.pomodoroRemainingSeconds)
                             : String(format: "%.1fs", timerService.stopwatchElapsedSeconds))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    // System Summary
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 38, height: 38)
                        Image(systemName: "macbook")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MacBook Air M2")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("CPU \(Int(metricsService.metrics.cpuUsagePercent))% • RAM \(Int(metricsService.metrics.ramPercent))% • Battery \(Int(metricsService.metrics.batteryLevel * 100))%")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Quick Expand to Full Tabs
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        stateManager.openDetailed()
                    }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Full Interactive Panel")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 14)
            
            // Secondary row: Quick controls
            HStack(spacing: 16) {
                if mediaService.currentTrack.isPlaying {
                    Button {
                        mediaService.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        mediaService.togglePlayPause()
                    } label: {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(settingsStore.accentColor)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        mediaService.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Shortcut badges to quickly jump to any tab
                HStack(spacing: 6) {
                    ForEach([WidgetType.shelf, WidgetType.clipboard, WidgetType.timer, WidgetType.tools]) { widget in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                stateManager.openDetailed(widget: widget)
                            }
                        } label: {
                            Image(systemName: widget.iconName)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(widget.rawValue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }
    
    private func formatSeconds(_ total: Int) -> String {
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
