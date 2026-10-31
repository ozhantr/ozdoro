# Architecture

OzDoro uses SwiftUI for the popover content and AppKit for the menu bar item.

| Component | Responsibility |
| --- | --- |
| `Core/PomodoroCycle.swift` | Four-round state machine and session durations |
| `Core/PomodoroTimerEngine.swift` | Countdown, pause/resume, transitions, restart and reset |
| `Services/PomodoroTimer.swift` | Main-actor state, display ticks, wake notifications, preferences and sound events |
| `Services/SystemSoundPlayer.swift` | Installed sound discovery and playback |
| `App/OzDoroAppDelegate.swift` | Stable status item and nonanimated popover |
| `UI/MenuBarContent.swift` | SwiftUI controls |
| `UI/L10n.swift` | Localized text accessors |
| `Resources/Localizable.xcstrings` | English, German and Turkish translations |

## Timer behavior

Each cycle contains four 25-minute focus sessions. The first three lead to five-minute breaks; the fourth leads to the configured long break. Breaks start automatically, while the next focus session waits for Start. Restart preserves round progress; Reset cycle clears it.

The engine receives a date from its caller and calculates remaining time from a deadline. Fractional seconds are retained across pauses and rounded only for display. Completion events trigger sound once. The macOS adapter reconciles the engine on ticks and wake notifications.

If focus expires during sleep, a full break starts on wake. If a break expires during sleep, the next focus session is ready but stopped. Manual system-clock changes affect deadlines. Preferences persist across launches; timer progress does not.

The status item and popover are owned independently of SwiftUI updates, so countdown changes do not recreate them.

## Extending the project

Core logic has no UI dependencies and is tested through Swift Package Manager. Add new app source files to the Xcode target as well as the filesystem; package test files are discovered automatically.
