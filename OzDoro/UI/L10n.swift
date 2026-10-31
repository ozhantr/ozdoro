import Foundation

/// All user-facing strings live here and are translated in Localizable.xcstrings.
/// Never translate sound filenames: those are names of resources installed on the Mac.
enum L10n {
    static var focus: String { NSLocalizedString("Focus", comment: "Focus timer phase") }
    static var shortBreak: String { NSLocalizedString("Short break", comment: "Five-minute rest phase") }
    static var longBreak: String {
        NSLocalizedString("Long break", comment: "Long rest phase and preference label")
    }

    static func phaseTitle(_ phase: PomodoroPhase) -> String {
        switch phase {
        case .focus: return focus
        case .shortBreak: return shortBreak
        case .longBreak: return longBreak
        }
    }

    static var cycleTitle: String {
        NSLocalizedString("4-round Pomodoro cycle", comment: "Header above the four progress circles")
    }
    static var upNext: String { NSLocalizedString("Up next", comment: "Label of upcoming timer phase") }
    static var start: String { NSLocalizedString("Start", comment: "Start a stopped session") }
    static var pause: String { NSLocalizedString("Pause", comment: "Pause running session") }
    static var resume: String { NSLocalizedString("Continue", comment: "Resume a paused session") }
    static var restart: String {
        NSLocalizedString("Restart", comment: "Restart current session, keeping round progress")
    }
    static var skipBreak: String {
        NSLocalizedString("Skip break", comment: "Skip current short or long break")
    }
    static var alertSound: String { NSLocalizedString("Alert sound", comment: "Alert sound setting") }
    static var noSound: String { NSLocalizedString("None", comment: "Silent alert sound choice") }
    static var resetCycle: String { NSLocalizedString("Reset cycle", comment: "Reset every completed round") }
    static var quit: String { NSLocalizedString("Quit OzDoro", comment: "Quit menu bar application") }
    static var restartHelp: String {
        NSLocalizedString(
            "Restart this focus or break session without changing the round",
            comment: "Restart button tooltip")
    }
    static var resetCycleHelp: String {
        NSLocalizedString(
            "Clear all round progress and return to round 1", comment: "Reset cycle button tooltip")
    }
    static var previewSoundHelp: String {
        NSLocalizedString("Preview selected sound", comment: "Sound preview button tooltip")
    }
    static var appTooltip: String {
        NSLocalizedString("OzDoro Pomodoro timer", comment: "Status item hover tooltip")
    }
    static var firstThreeRounds: String {
        NSLocalizedString(
            "Rounds 1–3: 25 min focus → 5 min break", comment: "Schedule for the first three rounds")
    }
    static var automaticBreaksHint: String {
        NSLocalizedString(
            "Breaks start automatically · Focus waits for Start", comment: "Explains how sessions advance")
    }

    static func remainingTime(_ time: String) -> String {
        String(
            format: NSLocalizedString("Time remaining: %@", comment: "Countdown accessibility label"),
            locale: .current, time)
    }
    static func completedRounds(_ count: Int) -> String {
        String(
            format: NSLocalizedString("All %lld rounds completed", comment: "Shown during long break"),
            locale: .current, Int64(count))
    }
    static func roundOfTotal(_ round: Int, total: Int) -> String {
        String(
            format: NSLocalizedString("Round %lld of %lld", comment: "Current focus round and total rounds"),
            locale: .current, Int64(round), Int64(total))
    }
    static func roundAccessibility(_ round: Int, completed: Bool, current: Bool) -> String {
        let format: String
        if completed {
            format = NSLocalizedString(
                "Round %lld: completed", comment: "Completed round accessibility label")
        } else if current {
            format = NSLocalizedString("Round %lld: current", comment: "Current round accessibility label")
        } else {
            format = NSLocalizedString("Round %lld: upcoming", comment: "Upcoming round accessibility label")
        }
        return String(format: format, locale: .current, Int64(round))
    }
    static func finalRound(longBreakMinutes: Int) -> String {
        String(
            format: NSLocalizedString(
                "Round 4: 25 min focus → %lld min long break", comment: "Fourth round ends with long break"),
            locale: .current, Int64(longBreakMinutes))
    }
    static func minutes(_ value: Int) -> String {
        String(
            format: NSLocalizedString("%lld minutes", comment: "Long break length picker, values 15–30"),
            locale: .current, Int64(value))
    }
    static var nextFocus: String {
        NSLocalizedString("Focus · 25 min", comment: "Next session summary")
    }
    static var nextFocusNewCycle: String {
        NSLocalizedString("Focus · 25 min (new cycle)", comment: "Next session after long break")
    }
    static var nextShortBreak: String {
        NSLocalizedString("Short break · 5 min", comment: "Next session summary")
    }
    static func nextLongBreak(_ minutes: Int) -> String {
        String(
            format: NSLocalizedString("Long break · %lld min", comment: "Next long break summary"),
            locale: .current, Int64(minutes))
    }
}
