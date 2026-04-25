import XCTest
@testable import PoomsaeFlow

/// Tests for the session-summary counting logic that lives in SessionCompleteView.
final class SessionCompleteViewTests: XCTestCase {

    // MARK: - Fixtures

    private func makeView(attempts: [FormAttempt]) -> SessionCompleteView {
        SessionCompleteView(attempts: attempts, onGoAgain: {}, onDone: {})
    }

    private func makeAttempt(outcome: AttemptOutcome, retryCount: Int) -> FormAttempt {
        FormAttempt(sessionID: UUID(), formID: UUID(), userID: UUID(),
                    outcome: outcome, retryCount: retryCount)
    }

    // MARK: - retriedCount

    /// A skipped attempt with retryCount == 1 contributes 1 to the total retry tap sum.
    func test_retriedCount_includesSkippedAttemptsWithRetries() {
        let view = makeView(attempts: [makeAttempt(outcome: .skipped, retryCount: 1)])
        XCTAssertEqual(view.retriedCount, 1)
    }

    /// A passed-after-retry attempt with retryCount == 1 contributes 1 to the sum.
    func test_retriedCount_includesPassedAfterRetry() {
        let view = makeView(attempts: [makeAttempt(outcome: .passedAfterRetry, retryCount: 1)])
        XCTAssertEqual(view.retriedCount, 1)
    }

    /// A clean pass with retryCount == 0 contributes 0 — sum stays zero.
    func test_retriedCount_excludesCleanPass() {
        let view = makeView(attempts: [makeAttempt(outcome: .passed, retryCount: 0)])
        XCTAssertEqual(view.retriedCount, 0)
    }

    /// A skipped attempt with retryCount == 0 contributes 0 — sum stays zero.
    func test_retriedCount_excludesSkippedWithNoRetries() {
        let view = makeView(attempts: [makeAttempt(outcome: .skipped, retryCount: 0)])
        XCTAssertEqual(view.retriedCount, 0)
    }

    // MARK: - nailedCount

    /// A passedAfterRetry attempt counts as nailed (the form was completed) and
    /// its retryCount contributes to the retry-attempts sum.
    func test_nailedCount_includesPassedAfterRetry() {
        let view = makeView(attempts: [makeAttempt(outcome: .passedAfterRetry, retryCount: 2)])
        XCTAssertEqual(view.nailedCount, 1)
        XCTAssertEqual(view.retriedCount, 2)
    }

    /// Three attempts with retryCount [1, 3, 0] produce retriedCount == 4 (total retry taps).
    func test_retriedCount_sumsAllRetryTaps() {
        let view = makeView(attempts: [
            makeAttempt(outcome: .passedAfterRetry, retryCount: 1),
            makeAttempt(outcome: .passedAfterRetry, retryCount: 3),
            makeAttempt(outcome: .passed, retryCount: 0)
        ])
        XCTAssertEqual(view.retriedCount, 4)
    }
}
