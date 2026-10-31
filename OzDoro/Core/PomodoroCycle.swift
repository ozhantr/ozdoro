import Foundation

/// Each completed focus session is followed by a break.
/// The fourth focus session leads directly to the long break.
enum PomodoroPhase: String, Equatable {
    case focus
    case shortBreak
    case longBreak

    var symbol: String {
        switch self {
        case .focus: return "timer"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "moon.stars"
        }
    }

    /// Breaks start as soon as a focus session finishes.
    /// Focus sessions wait until the user explicitly presses Start.
    var startsAutomatically: Bool {
        switch self {
        case .focus: return false
        case .shortBreak, .longBreak: return true
        }
    }
}

struct PomodoroPlan: Equatable {
    let focusSeconds = 25 * 60
    let shortBreakSeconds = 5 * 60
    let longBreakMinutes: Int

    init(longBreakMinutes: Int) {
        self.longBreakMinutes = min(30, max(15, longBreakMinutes))
    }

    func seconds(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus: return focusSeconds
        case .shortBreak: return shortBreakSeconds
        case .longBreak: return longBreakMinutes * 60
        }
    }
}

/// Fixed Pomodoro sequence: 25/5, 25/5, 25/5, 25/long break.
/// This domain model does not depend on the timer, AppKit, or SwiftUI.
struct PomodoroCycle: Equatable {
    static let roundsPerCycle = 4

    private(set) var phase: PomodoroPhase = .focus
    private(set) var completedFocusSessions = 0

    /// During a break, show the round whose focus session just finished.
    var currentRound: Int {
        switch phase {
        case .focus:
            return min(completedFocusSessions + 1, Self.roundsPerCycle)
        case .shortBreak, .longBreak:
            return completedFocusSessions
        }
    }

    var nextPhase: PomodoroPhase {
        switch phase {
        case .focus:
            return completedFocusSessions + 1 == Self.roundsPerCycle ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    mutating func completeSession() {
        switch phase {
        case .focus:
            completedFocusSessions += 1
            phase = completedFocusSessions == Self.roundsPerCycle ? .longBreak : .shortBreak
        case .shortBreak:
            phase = .focus
        case .longBreak:
            startNewCycle()
        }
    }

    /// Skipping a break never grants credit for an unfinished focus session.
    @discardableResult
    mutating func skipBreak() -> Bool {
        guard phase != .focus else { return false }
        completeSession()
        return true
    }

    mutating func startNewCycle() {
        self = PomodoroCycle()
    }
}
