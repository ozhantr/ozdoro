import XCTest

@testable import OzDoroCore

final class PomodoroCycleTests: XCTestCase {
    func testRoundCountIsFixedAtFour() {
        XCTAssertEqual(PomodoroCycle.roundsPerCycle, 4)
    }

    func testFocusSessionTransitions() {
        var cycle = PomodoroCycle()

        for round in 1...PomodoroCycle.roundsPerCycle {
            XCTAssertEqual(cycle.phase, .focus)
            XCTAssertEqual(cycle.currentRound, round)
            XCTAssertEqual(cycle.nextPhase, round == 4 ? .longBreak : .shortBreak)
            cycle.completeSession()
            XCTAssertEqual(cycle.completedFocusSessions, round)
            XCTAssertEqual(cycle.phase, round == 4 ? .longBreak : .shortBreak)
            XCTAssertEqual(cycle.currentRound, round)

            if round < 4 {
                cycle.completeSession()
                XCTAssertEqual(cycle.phase, .focus)
            }
        }
    }

    func testFourthFocusGoesDirectlyToLongBreak() {
        var cycle = PomodoroCycle()
        for _ in 0..<3 {
            cycle.completeSession()  // Focus
            cycle.completeSession()  // Short break
        }
        XCTAssertEqual(cycle.currentRound, 4)
        cycle.completeSession()
        XCTAssertEqual(cycle.phase, .longBreak)  // No extra 5-min break
        XCTAssertEqual(cycle.completedFocusSessions, 4)
    }

    func testLongBreakCompletionResetsTheCycle() {
        var cycle = PomodoroCycle()
        for _ in 0..<3 {
            cycle.completeSession()
            cycle.completeSession()
        }
        cycle.completeSession()  // Focus #4 => long break
        cycle.completeSession()  // Long break completed
        XCTAssertEqual(cycle, PomodoroCycle())
        XCTAssertEqual(cycle.currentRound, 1)
    }

    func testSkippingShortBreakPreservesCompletedCount() {
        var cycle = PomodoroCycle()
        XCTAssertFalse(cycle.skipBreak())
        cycle.completeSession()  // Focus #1
        XCTAssertTrue(cycle.skipBreak())
        XCTAssertEqual(cycle.phase, .focus)
        XCTAssertEqual(cycle.currentRound, 2)
        XCTAssertEqual(cycle.completedFocusSessions, 1)
    }

    func testSkippingLongBreakStartsNewCycle() {
        var cycle = PomodoroCycle()
        for _ in 0..<3 {
            cycle.completeSession()
            cycle.completeSession()
        }
        cycle.completeSession()
        XCTAssertEqual(cycle.phase, .longBreak)
        XCTAssertTrue(cycle.skipBreak())
        XCTAssertEqual(cycle, PomodoroCycle())
    }

    func testBreaksStartAutomaticallyButFocusWaitsForStart() {
        var cycle = PomodoroCycle()
        XCTAssertFalse(cycle.phase.startsAutomatically)

        cycle.completeSession()  // Focus #1 -> short break
        XCTAssertEqual(cycle.phase, .shortBreak)
        XCTAssertTrue(cycle.phase.startsAutomatically)

        cycle.completeSession()  // Short break -> focus #2
        XCTAssertEqual(cycle.phase, .focus)
        XCTAssertFalse(cycle.phase.startsAutomatically)

        // Finish focus rounds #2 and #3, including their short breaks.
        for _ in 0..<2 {
            cycle.completeSession()
            XCTAssertTrue(cycle.phase.startsAutomatically)
            cycle.completeSession()
            XCTAssertFalse(cycle.phase.startsAutomatically)
        }

        cycle.completeSession()  // Focus #4 -> long break
        XCTAssertEqual(cycle.phase, .longBreak)
        XCTAssertTrue(cycle.phase.startsAutomatically)

        cycle.completeSession()  // Long break -> new cycle
        XCTAssertEqual(cycle.phase, .focus)
        XCTAssertFalse(cycle.phase.startsAutomatically)
    }

    func testSkippedBreakNeverAutoStartsNextFocus() {
        var cycle = PomodoroCycle()
        cycle.completeSession()  // Focus -> short break
        XCTAssertTrue(cycle.skipBreak())
        XCTAssertEqual(cycle.phase, .focus)
        XCTAssertFalse(cycle.phase.startsAutomatically)
    }

    func testNewCycleResetsProgress() {
        var cycle = PomodoroCycle()
        cycle.completeSession()
        cycle.completeSession()
        XCTAssertEqual(cycle.completedFocusSessions, 1)
        cycle.startNewCycle()
        XCTAssertEqual(cycle, PomodoroCycle())
    }

    func testPlanDurationsAndLongBreakLimits() {
        let plan = PomodoroPlan(longBreakMinutes: 20)
        XCTAssertEqual(plan.seconds(for: .focus), 1500)
        XCTAssertEqual(plan.seconds(for: .shortBreak), 300)
        XCTAssertEqual(plan.seconds(for: .longBreak), 1200)
        XCTAssertEqual(PomodoroPlan(longBreakMinutes: 10).longBreakMinutes, 15)
        XCTAssertEqual(PomodoroPlan(longBreakMinutes: 45).longBreakMinutes, 30)
    }
}
