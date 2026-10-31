import Foundation

/// Events are emitted only when a running session ends naturally.
/// User-initiated restart, reset, and skip never produce a completion event.
enum PomodoroTimerEvent: Equatable {
    case sessionCompleted(PomodoroPhase)
}

/// A deterministic countdown engine shared by the app and its unit tests.
///
/// The caller supplies the current date, so tests do not need to sleep or wait
/// for a real 25-minute session. UI, sound, persistence and OS wake notifications
/// remain outside this type.
struct PomodoroTimerEngine {
    private(set) var cycle = PomodoroCycle()
    // Round only for display; preserve fractional seconds across pause/resume.
    var remainingSeconds: Int { Int(ceil(remainingTime)) }
    private var remainingTime: TimeInterval = 25 * 60
    private(set) var isRunning = false
    private(set) var hasStarted = false
    private(set) var longBreakMinutes: Int

    private var deadline: Date?
    private var plan: PomodoroPlan {
        PomodoroPlan(longBreakMinutes: longBreakMinutes)
    }

    init(longBreakMinutes: Int = 20) {
        let normalized = PomodoroPlan(longBreakMinutes: longBreakMinutes).longBreakMinutes
        self.longBreakMinutes = normalized
    }

    var phase: PomodoroPhase { cycle.phase }

    /// Begins a paused/unstarted session. Repeated starts are no-ops.
    mutating func start(at now: Date) {
        guard !isRunning else { return }
        deadline = now.addingTimeInterval(remainingTime)
        isRunning = true
        hasStarted = true
    }

    /// Updates the countdown from elapsed wall-clock time, never by decrementing
    /// a counter. A delayed tick (including after Mac sleep) ends at most one
    /// session and starts a full-length break *at the observation time*.
    /// This intentionally never claims that unattended breaks were completed.
    @discardableResult
    mutating func advance(to now: Date) -> [PomodoroTimerEvent] {
        guard isRunning, let deadline else { return [] }

        remainingTime = max(0, deadline.timeIntervalSince(now))
        guard remainingTime == 0 else { return [] }

        let completedPhase = phase
        isRunning = false
        hasStarted = false
        self.deadline = nil
        cycle.completeSession()
        remainingTime = TimeInterval(plan.seconds(for: phase))

        // Work always hands off to a break immediately; completed breaks
        // require the user to start the next focus session explicitly.
        if phase.startsAutomatically {
            start(at: now)
        }
        return [.sessionCompleted(completedPhase)]
    }

    /// Captures the elapsed time before pausing. If the session just ended,
    /// the transition event is returned to the caller for sound playback.
    @discardableResult
    mutating func pause(at now: Date) -> [PomodoroTimerEvent] {
        let events = advance(to: now)
        isRunning = false
        deadline = nil
        return events
    }

    mutating func restartCurrentSession() {
        isRunning = false
        hasStarted = false
        deadline = nil
        remainingTime = TimeInterval(plan.seconds(for: phase))
    }

    mutating func startNewCycle() {
        isRunning = false
        hasStarted = false
        deadline = nil
        cycle.startNewCycle()
        remainingTime = TimeInterval(plan.seconds(for: .focus))
    }

    /// Skips only breaks. It cannot grant credit for incomplete focus work.
    @discardableResult
    mutating func skipBreak() -> Bool {
        guard cycle.skipBreak() else { return false }
        isRunning = false
        hasStarted = false
        deadline = nil
        remainingTime = TimeInterval(plan.seconds(for: phase))
        return true
    }

    mutating func setLongBreakMinutes(_ minutes: Int) {
        longBreakMinutes = PomodoroPlan(longBreakMinutes: minutes).longBreakMinutes
        if !hasStarted && phase == .longBreak {
            remainingTime = TimeInterval(plan.seconds(for: .longBreak))
        }
    }
}
