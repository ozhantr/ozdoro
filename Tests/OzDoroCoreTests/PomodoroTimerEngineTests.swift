import Foundation
import XCTest

@testable import OzDoroCore

/// Tests the exact countdown/transition engine used by the macOS application.
/// Dates are controlled deterministically; no 25-minute wall-clock test runs.
final class PomodoroTimerEngineTests: XCTestCase {
    private let beginning = Date(timeIntervalSince1970: 1_700_000_000)

    func testCountdownUsesDeadlineRatherThanNumberOfTicks() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)

        XCTAssertTrue(timer.advance(to: beginning.addingTimeInterval(42)).isEmpty)
        XCTAssertEqual(timer.remainingSeconds, 1_458)

        // Skipped or delayed ticks must not cause a slow-running timer.
        XCTAssertTrue(timer.advance(to: beginning.addingTimeInterval(90.2)).isEmpty)
        XCTAssertEqual(timer.remainingSeconds, 1_410)
        XCTAssertEqual(timer.cycle.currentRound, 1)
    }

    func testFocusCompletesOnceAndShortBreakStartsAutomatically() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)

        let events = timer.advance(to: beginning.addingTimeInterval(1_500))
        XCTAssertEqual(events, [.sessionCompleted(.focus)])
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.cycle.completedFocusSessions, 1)
        XCTAssertEqual(timer.remainingSeconds, 300)
        XCTAssertTrue(timer.isRunning)
        XCTAssertTrue(timer.hasStarted)

        // A duplicate timer callback at the same instant must not replay sound.
        XCTAssertTrue(timer.advance(to: beginning.addingTimeInterval(1_500)).isEmpty)
    }

    func testShortBreakFinishesWithNextFocusStopped() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        timer.advance(to: beginning.addingTimeInterval(1_500))

        let events = timer.advance(to: beginning.addingTimeInterval(1_800))
        XCTAssertEqual(events, [.sessionCompleted(.shortBreak)])
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.cycle.currentRound, 2)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.hasStarted)

        XCTAssertTrue(timer.advance(to: beginning.addingTimeInterval(9_000)).isEmpty)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
    }

    func testPauseAndResumePreserveRemainingTime() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        XCTAssertTrue(timer.pause(at: beginning.addingTimeInterval(95.25)).isEmpty)
        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.hasStarted)
        XCTAssertEqual(timer.remainingSeconds, 1_405)

        // Time spent paused does not decrease the countdown.
        timer.advance(to: beginning.addingTimeInterval(2_000))
        XCTAssertEqual(timer.remainingSeconds, 1_405)
        timer.start(at: beginning.addingTimeInterval(2_000))
        timer.advance(to: beginning.addingTimeInterval(2_005))
        XCTAssertEqual(timer.remainingSeconds, 1_400)
    }

    func testRepeatedFractionalPausesDoNotExtendSession() {
        var timer = PomodoroTimerEngine()
        var now = beginning
        for _ in 0..<4 {
            timer.start(at: now)
            now = now.addingTimeInterval(0.25)
            XCTAssertTrue(timer.pause(at: now).isEmpty)
            now = now.addingTimeInterval(10)
        }
        XCTAssertEqual(timer.remainingSeconds, 1_499)
        timer.start(at: now)
        XCTAssertEqual(timer.advance(to: now.addingTimeInterval(1_499)), [.sessionCompleted(.focus)])
    }

    func testLongBreakPreferenceDoesNotResizeStartedBreak() {
        var timer = PomodoroTimerEngine()
        var now = beginning
        for round in 1...4 {
            timer.start(at: now)
            now = now.addingTimeInterval(1_500)
            timer.advance(to: now)
            if round < 4 { timer.skipBreak() }
        }
        timer.setLongBreakMinutes(30)
        XCTAssertEqual(timer.remainingSeconds, 1_200)
        timer.pause(at: now.addingTimeInterval(10))
        timer.setLongBreakMinutes(15)
        XCTAssertEqual(timer.remainingSeconds, 1_190)
        timer.restartCurrentSession()
        XCTAssertEqual(timer.remainingSeconds, 900)
        timer.setLongBreakMinutes(25)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
    }

    func testRestartPreservesRoundAndDoesNotEmitCompletion() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        timer.advance(to: beginning.addingTimeInterval(1_500))  // short break
        timer.advance(to: beginning.addingTimeInterval(1_540))
        timer.restartCurrentSession()

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.cycle.completedFocusSessions, 1)
        XCTAssertEqual(timer.remainingSeconds, 300)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.hasStarted)
    }

    func testSkipBreakNeverCreditsUnfinishedFocus() {
        var timer = PomodoroTimerEngine()
        XCTAssertFalse(timer.skipBreak())
        timer.start(at: beginning)
        timer.advance(to: beginning.addingTimeInterval(1_500))
        XCTAssertTrue(timer.skipBreak())
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.cycle.completedFocusSessions, 1)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
    }

    func testFourthWorkSessionStartsLongBreakWithoutExtraShortBreak() {
        var timer = PomodoroTimerEngine(longBreakMinutes: 25)
        var now = beginning

        for round in 1...4 {
            timer.start(at: now)
            now = now.addingTimeInterval(1_500)
            XCTAssertEqual(timer.advance(to: now), [.sessionCompleted(.focus)])
            if round < 4 {
                XCTAssertEqual(timer.phase, .shortBreak)
                now = now.addingTimeInterval(300)
                XCTAssertEqual(timer.advance(to: now), [.sessionCompleted(.shortBreak)])
                XCTAssertFalse(timer.isRunning)
            }
        }
        XCTAssertEqual(timer.phase, .longBreak)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.cycle.completedFocusSessions, 4)

        now = now.addingTimeInterval(1_500)
        XCTAssertEqual(timer.advance(to: now), [.sessionCompleted(.longBreak)])
        XCTAssertEqual(timer.cycle, PomodoroCycle())
        XCTAssertEqual(timer.remainingSeconds, 1_500)
        XCTAssertFalse(timer.isRunning)
    }

    func testWakeAfterLongSleepDoesNotInventCompletedBreaks() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        let wakeTime = beginning.addingTimeInterval(60 * 60 * 4)
        XCTAssertEqual(timer.advance(to: wakeTime), [.sessionCompleted(.focus)])
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds, 300)

        // Repeated wake callback at the same timestamp cannot complete break.
        XCTAssertEqual(timer.advance(to: wakeTime), [])
        XCTAssertEqual(timer.cycle.completedFocusSessions, 1)
        XCTAssertEqual(timer.remainingSeconds, 300)
    }

    func testChangingLongBreakOnlyAdjustsUnstartedLongBreak() {
        var timer = PomodoroTimerEngine(longBreakMinutes: 20)
        timer.setLongBreakMinutes(5)
        XCTAssertEqual(timer.longBreakMinutes, 15)
        timer.setLongBreakMinutes(30)
        XCTAssertEqual(timer.longBreakMinutes, 30)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
    }

    func testResetCycleClearsProgressAndStopsClock() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        timer.advance(to: beginning.addingTimeInterval(1_500))
        timer.startNewCycle()
        XCTAssertEqual(timer.cycle, PomodoroCycle())
        XCTAssertEqual(timer.remainingSeconds, 1_500)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.hasStarted)
        XCTAssertTrue(timer.advance(to: beginning.addingTimeInterval(2_000)).isEmpty)
    }

    func testWakeAfterMissedBreakEndsInStoppedFocus() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        timer.advance(to: beginning.addingTimeInterval(1_500))

        let wakeTime = beginning.addingTimeInterval(60 * 60 * 3)
        XCTAssertEqual(timer.advance(to: wakeTime), [.sessionCompleted(.shortBreak)])
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.cycle.currentRound, 2)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds, 1_500)
    }

    func testPauseExactlyAtDeadlineEmitsCompletionOnce() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        let due = beginning.addingTimeInterval(1_500)
        XCTAssertEqual(timer.pause(at: due), [.sessionCompleted(.focus)])
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds, 300)
        XCTAssertTrue(timer.advance(to: due).isEmpty)
    }

    func testMultipleStartCallsDoNotExtendActiveDeadline() {
        var timer = PomodoroTimerEngine()
        timer.start(at: beginning)
        timer.start(at: beginning.addingTimeInterval(300))
        XCTAssertEqual(timer.advance(to: beginning.addingTimeInterval(1_500)), [.sessionCompleted(.focus)])
    }
}
