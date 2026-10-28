import Foundation
import AppKit
import IOKit.pwr_mgt

public enum PomodoroPhase: String, CaseIterable, Sendable {
    case work = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    public var defaultDurationSeconds: Int {
        switch self {
        case .work: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
}

public enum TimerMode: String, CaseIterable, Sendable {
    case pomodoro = "Pomodoro"
    case countdown = "Countdown"
    case stopwatch = "Stopwatch"
}

@MainActor
public final class TimerService: ObservableObject {
    public static let shared = TimerService()
    
    @Published public var activeMode: TimerMode = .pomodoro
    
    // Pomodoro
    @Published public var pomodoroPhase: PomodoroPhase = .work
    @Published public var pomodoroRemainingSeconds: Int = 25 * 60
    @Published public var pomodoroIsRunning: Bool = false
    @Published public var pomodoroCompletedCycles: Int = 0
    
    // Countdown
    @Published public var countdownRemainingSeconds: Int = 10 * 60
    @Published public var countdownTotalSeconds: Int = 10 * 60
    @Published public var countdownIsRunning: Bool = false
    
    // Stopwatch
    @Published public var stopwatchElapsedSeconds: Double = 0.0
    @Published public var stopwatchIsRunning: Bool = false
    @Published public var stopwatchLaps: [Double] = []
    
    // Keep-Awake (Caffeinate)
    @Published public var isKeepAwakeActive: Bool = false {
        didSet {
            toggleKeepAwake(enable: isKeepAwakeActive)
        }
    }
    private var keepAwakeAssertionID: IOPMAssertionID = 0
    
    private var ticker: Timer?
    
    public init() {
        startTicker()
    }
    
    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    private var lastTickTime: Date = Date()
    private var secondAccumulator: Double = 0.0
    
    private func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTickTime)
        lastTickTime = now
        
        // Stopwatch
        if stopwatchIsRunning {
            stopwatchElapsedSeconds += dt
        }
        
        secondAccumulator += dt
        if secondAccumulator >= 1.0 {
            secondAccumulator -= 1.0
            
            // Pomodoro
            if pomodoroIsRunning {
                if pomodoroRemainingSeconds > 0 {
                    pomodoroRemainingSeconds -= 1
                } else {
                    pomodoroCompleted()
                }
            }
            
            // Countdown
            if countdownIsRunning {
                if countdownRemainingSeconds > 0 {
                    countdownRemainingSeconds -= 1
                } else {
                    countdownCompleted()
                }
            }
        }
    }
    
    // MARK: - Pomodoro Controls
    public func togglePomodoro() {
        pomodoroIsRunning.toggle()
    }
    
    public func resetPomodoro() {
        pomodoroIsRunning = false
        pomodoroRemainingSeconds = pomodoroPhase.defaultDurationSeconds
    }
    
    public func skipPomodoroPhase() {
        pomodoroIsRunning = false
        switch pomodoroPhase {
        case .work:
            pomodoroCompletedCycles += 1
            if pomodoroCompletedCycles % 4 == 0 {
                pomodoroPhase = .longBreak
            } else {
                pomodoroPhase = .shortBreak
            }
        case .shortBreak, .longBreak:
            pomodoroPhase = .work
        }
        pomodoroRemainingSeconds = pomodoroPhase.defaultDurationSeconds
    }
    
    private func pomodoroCompleted() {
        NSSound.beep()
        skipPomodoroPhase()
    }
    
    // MARK: - Countdown Controls
    public func toggleCountdown() {
        countdownIsRunning.toggle()
    }
    
    public func resetCountdown() {
        countdownIsRunning = false
        countdownRemainingSeconds = countdownTotalSeconds
    }
    
    public func setCountdown(minutes: Int) {
        countdownIsRunning = false
        countdownTotalSeconds = minutes * 60
        countdownRemainingSeconds = countdownTotalSeconds
    }
    
    private func countdownCompleted() {
        countdownIsRunning = false
        NSSound.beep()
    }
    
    // MARK: - Stopwatch Controls
    public func toggleStopwatch() {
        stopwatchIsRunning.toggle()
    }
    
    public func resetStopwatch() {
        stopwatchIsRunning = false
        stopwatchElapsedSeconds = 0.0
        stopwatchLaps.removeAll()
    }
    
    public func recordLap() {
        stopwatchLaps.append(stopwatchElapsedSeconds)
    }
    
    // MARK: - Keep Awake (Caffeinate)
    private func toggleKeepAwake(enable: Bool) {
        if enable {
            let reason = "MacDynamicIsland Keep Awake Active" as CFString
            let success = IOPMAssertionCreateWithName(
                kIOPMAssertionTypeNoDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &keepAwakeAssertionID
            )
            if success != kIOReturnSuccess {
                print("[TimerService] Failed to create power assertion: \(success)")
            }
        } else {
            if keepAwakeAssertionID != 0 {
                IOPMAssertionRelease(keepAwakeAssertionID)
                keepAwakeAssertionID = 0
            }
        }
    }
    
    isolated deinit {
        ticker?.invalidate()
        if keepAwakeAssertionID != 0 {
            IOPMAssertionRelease(keepAwakeAssertionID)
        }
    }
}
