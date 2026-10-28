import SwiftUI

public struct TimerWidgetView: View {
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Mode Picker
            HStack(spacing: 6) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Button {
                        timerService.activeMode = mode
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: timerService.activeMode == mode ? .bold : .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(timerService.activeMode == mode ? settingsStore.accentColor.opacity(0.3) : Color.white.opacity(0.06))
                            .foregroundColor(timerService.activeMode == mode ? .white : .white.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Keep Awake Toggle
                Button {
                    timerService.isKeepAwakeActive.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: timerService.isKeepAwakeActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                            .font(.system(size: 11))
                        Text("Keep Awake")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(timerService.isKeepAwakeActive ? Color.orange.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(timerService.isKeepAwakeActive ? .orange : .white.opacity(0.6))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Prevent Mac from sleeping (Caffeinate)")
            }
            
            // Mode-specific content
            switch timerService.activeMode {
            case .pomodoro:
                pomodoroView
            case .countdown:
                countdownView
            case .stopwatch:
                stopwatchView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Pomodoro View
    private var pomodoroView: some View {
        VStack(spacing: 10) {
            HStack {
                Text(timerService.pomodoroPhase.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(phaseColor(timerService.pomodoroPhase))
                
                Spacer()
                
                Text("Cycle #\(timerService.pomodoroCompletedCycles + 1)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Big Timer Display
            Text(formatSeconds(timerService.pomodoroRemainingSeconds))
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            // Controls
            HStack(spacing: 20) {
                Button {
                    timerService.resetPomodoro()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset Session")
                
                Button {
                    timerService.togglePomodoro()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: timerService.pomodoroIsRunning ? "pause.fill" : "play.fill")
                        Text(timerService.pomodoroIsRunning ? "Pause" : "Start")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(phaseColor(timerService.pomodoroPhase))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    timerService.skipPomodoroPhase()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Skip Phase")
            }
        }
    }
    
    // MARK: - Countdown View
    private var countdownView: some View {
        VStack(spacing: 10) {
            // Presets
            HStack(spacing: 8) {
                ForEach([1, 5, 10, 15, 25], id: \.self) { mins in
                    Button("\(mins)m") {
                        timerService.setCountdown(minutes: mins)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(timerService.countdownTotalSeconds == mins * 60 ? settingsStore.accentColor.opacity(0.3) : Color.white.opacity(0.06))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }
            
            Text(formatSeconds(timerService.countdownRemainingSeconds))
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Button {
                    timerService.resetCountdown()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button {
                    timerService.toggleCountdown()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: timerService.countdownIsRunning ? "pause.fill" : "play.fill")
                        Text(timerService.countdownIsRunning ? "Pause" : "Start")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(settingsStore.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Stopwatch View
    private var stopwatchView: some View {
        VStack(spacing: 8) {
            Text(formatStopwatch(timerService.stopwatchElapsedSeconds))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                Button {
                    timerService.resetStopwatch()
                } label: {
                    Text("Reset")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white.opacity(0.8))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    timerService.toggleStopwatch()
                } label: {
                    Text(timerService.stopwatchIsRunning ? "Stop" : "Start")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(timerService.stopwatchIsRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    timerService.recordLap()
                } label: {
                    Text("Lap")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white.opacity(0.8))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!timerService.stopwatchIsRunning)
            }
            
            if !timerService.stopwatchLaps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(timerService.stopwatchLaps.enumerated()), id: \.offset) { idx, lap in
                            Text("L\(idx + 1): \(formatStopwatch(lap))")
                                .font(.system(size: 10, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .frame(height: 24)
            }
        }
    }
    
    private func phaseColor(_ phase: PomodoroPhase) -> Color {
        switch phase {
        case .work: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
    
    private func formatSeconds(_ total: Int) -> String {
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatStopwatch(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, ms)
    }
}
