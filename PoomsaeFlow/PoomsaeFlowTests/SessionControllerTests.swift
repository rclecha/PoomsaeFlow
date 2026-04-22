import XCTest
@testable import PoomsaeFlow

/// All tests run on the main actor because SessionController is @MainActor-bound
/// (implicit from SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
@MainActor
final class SessionControllerTests: XCTestCase {

    // MARK: - Fixtures

    private func makeController(formCount: Int) -> SessionController {
        let forms = (0..<formCount).map { i in
            TKDForm(id: UUID(), name: "Form \(i)", koreanName: nil,
                    family: .taegeuk, introducedAt: .white, videos: [], notes: nil)
        }
        let session = PracticeSession(id: UUID(), scope: .fullSet, order: .sequential,
                                      queue: forms, currentIndex: 0)
        return SessionController(session: session)
    }

    // MARK: - Initial state

    /// Sanity check: every session handed to the controller starts at the first form.
    func test_newSession_startsAtIndexZero() {
        let controller = makeController(formCount: 3)
        XCTAssertEqual(controller.session.currentIndex, 0)
    }

    /// An empty queue is already exhausted — isComplete must be true immediately.
    func test_emptySession_isCompleteAtStart() {
        let controller = makeController(formCount: 0)
        XCTAssertTrue(controller.isComplete)
    }

    /// No outcomes have been recorded yet.
    func test_newSession_attemptsIsEmpty() {
        let controller = makeController(formCount: 3)
        XCTAssertTrue(controller.attempts.isEmpty)
    }

    // MARK: - Advancing

    func test_recordPassed_advancesCurrentIndex() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.session.currentIndex, 1)
    }

    func test_recordSkipped_advancesCurrentIndexAndRecordsSkipped() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.skipped)
        XCTAssertEqual(controller.session.currentIndex, 1)
        XCTAssertEqual(controller.attempts.last?.outcome, .skipped)
    }

    // MARK: - Retry behaviour

    /// .retry is transient — the user isn't done with the form yet.
    func test_recordRetry_doesNotAdvanceCurrentIndex() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        XCTAssertEqual(controller.session.currentIndex, 0)
    }

    func test_recordRetry_incrementsRetryCount() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        XCTAssertEqual(controller.retryCount, 1)
        controller.recordOutcome(.retry)
        XCTAssertEqual(controller.retryCount, 2)
    }

    /// The distinction between .passed and .passedAfterRetry is resolved inside the
    /// controller so callers never have to track retry state themselves.
    func test_passedAfterOneOrMoreRetries_recordsPassedAfterRetry() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.attempts.last?.outcome, .passedAfterRetry)
    }

    /// Two retries then pass — outcome must still be .passedAfterRetry and the attempt
    /// must carry the full count so the summary can display it accurately.
    func test_multipleRetries_thenPassed_recordsPassedAfterRetryWithCorrectCount() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.attempts.last?.outcome, .passedAfterRetry)
        XCTAssertEqual(controller.attempts.last?.retryCount, 2)
    }

    /// A pass with no prior retries must still be .passed, not .passedAfterRetry.
    func test_passedWithNoRetries_recordsPassed() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.attempts.last?.outcome, .passed)
    }

    func test_terminalOutcome_resetsRetryCountToZero() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.retryCount, 0)
    }

    func test_skippedAfterRetries_resetsRetryCount() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.skipped)
        XCTAssertEqual(controller.retryCount, 0)
    }

    /// Regression: the controller must preserve retryCount on the FormAttempt even when
    /// the terminal outcome is .skipped. SessionCompleteView reads this field to surface
    /// retry information in the session summary.
    func test_skippedAfterRetry_preservesRetryCountOnAttempt() {
        let controller = makeController(formCount: 3)
        controller.recordOutcome(.retry)
        controller.recordOutcome(.skipped)
        XCTAssertEqual(controller.attempts.last?.retryCount, 1)
    }

    // MARK: - Attempts log

    /// .retry does not produce an attempt; only terminal outcomes grow the log.
    func test_attempts_growsByOnePerTerminalOutcome() {
        let controller = makeController(formCount: 3)
        XCTAssertEqual(controller.attempts.count, 0)
        controller.recordOutcome(.retry)          // transient — no growth
        XCTAssertEqual(controller.attempts.count, 0)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.attempts.count, 1)
        controller.recordOutcome(.skipped)
        XCTAssertEqual(controller.attempts.count, 2)
    }

    // MARK: - Completion & progress

    func test_isComplete_falseWhileFormsRemain_trueWhenExhausted() {
        let controller = makeController(formCount: 2)
        XCTAssertFalse(controller.isComplete)
        controller.recordOutcome(.passed)
        XCTAssertFalse(controller.isComplete)
        controller.recordOutcome(.passed)
        XCTAssertTrue(controller.isComplete)
    }

    func test_progress_zeroAtStart_halfwayThrough_oneWhenComplete() {
        let controller = makeController(formCount: 2)
        XCTAssertEqual(controller.progress, 0.0, accuracy: 0.001)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.progress, 0.5, accuracy: 0.001)
        controller.recordOutcome(.passed)
        XCTAssertEqual(controller.progress, 1.0, accuracy: 0.001)
    }
}
