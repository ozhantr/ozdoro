import AppKit
import Combine
import Foundation

/// Integrates the deterministic engine with macOS wake notifications, sound,
/// user defaults and a lightweight display ticker.
@MainActor
final class PomodoroTimer: ObservableObject {
    @Published private(set) var cycle = PomodoroCycle()
    @Published private(set) var remainingSeconds = 25 * 60
    @Published private(set) var isRunning = false
    @Published private(set) var hasStarted = false

    @Published var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: Keys.longBreakMinutes)
            engine.setLongBreakMinutes(longBreakMinutes)
            publishState()
        }
    }

    @Published var selectedSound: String {
        didSet {
            UserDefaults.standard.set(selectedSound, forKey: Keys.selectedSound)
        }
    }

    private enum Keys {
        static let longBreakMinutes = "longBreakMinutes"
        static let selectedSound = "selectedSound"
    }

    private var engine: PomodoroTimerEngine
    private let soundPlayer = SystemSoundPlayer()
    private var ticker: Timer?
    private var wakeObserver: NSObjectProtocol?

    init() {
        let defaults = UserDefaults.standard
        let savedMinutes = defaults.object(forKey: Keys.longBreakMinutes) as? Int ?? 20
        let normalizedMinutes = PomodoroPlan(longBreakMinutes: savedMinutes).longBreakMinutes
        longBreakMinutes = normalizedMinutes
        let savedSound = defaults.string(forKey: Keys.selectedSound) ?? SystemSounds.defaultSound
        selectedSound =
            savedSound == SystemSounds.silent || SystemSounds.availableNames.contains(savedSound)
            ? savedSound
            : (SystemSounds.availableNames.contains(SystemSounds.defaultSound)
                ? SystemSounds.defaultSound : SystemSounds.silent)
        engine = PomodoroTimerEngine(longBreakMinutes: normalizedMinutes)

        // A suspended run loop cannot deliver ticks. Reconcile on wake.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    deinit {
        ticker?.invalidate()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    var phase: PomodoroPhase { cycle.phase }
    var completedFocusSessions: Int { cycle.completedFocusSessions }
    var currentRound: Int { cycle.currentRound }

    var nextSessionDescription: String {
        switch cycle.nextPhase {
        case .focus:
            return phase == .longBreak ? L10n.nextFocusNewCycle : L10n.nextFocus
        case .shortBreak:
            return L10n.nextShortBreak
        case .longBreak:
            return L10n.nextLongBreak(longBreakMinutes)
        }
    }

    var formattedRemaining: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var primaryActionTitle: String {
        if isRunning { return L10n.pause }
        return hasStarted ? L10n.resume : L10n.start
    }

    var primaryActionSymbol: String { isRunning ? "pause.fill" : "play.fill" }

    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func resetCurrentSession() {
        stopTicker()
        engine.restartCurrentSession()
        publishState()
    }

    func startNewCycle() {
        stopTicker()
        engine.startNewCycle()
        publishState()
    }

    func skipBreak() {
        guard phase != .focus else { return }
        stopTicker()
        engine.skipBreak()
        publishState()
    }

    func previewSound() {
        soundPlayer.play(selectedSound)
    }

    private func start() {
        engine.start(at: Date())
        publishState()
        if engine.isRunning { startTickerIfNeeded() }
    }

    private func pause() {
        handle(engine.pause(at: Date()))
        stopTicker()
        publishState()
    }

    private func tick() {
        handle(engine.advance(to: Date()))
        publishState()
        if !engine.isRunning { stopTicker() }
    }

    private func handle(_ events: [PomodoroTimerEvent]) {
        for event in events {
            switch event {
            case .sessionCompleted:
                soundPlayer.play(selectedSound)
            }
        }
    }

    private func startTickerIfNeeded() {
        guard ticker == nil else { return }
        let newTicker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        newTicker.tolerance = 0.05
        RunLoop.main.add(newTicker, forMode: .common)
        ticker = newTicker
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func publishState() {
        if cycle != engine.cycle { cycle = engine.cycle }
        if remainingSeconds != engine.remainingSeconds {
            remainingSeconds = engine.remainingSeconds
        }
        if isRunning != engine.isRunning { isRunning = engine.isRunning }
        if hasStarted != engine.hasStarted { hasStarted = engine.hasStarted }
    }
}
