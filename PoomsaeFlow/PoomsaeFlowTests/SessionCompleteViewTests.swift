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

    /// A skipped attempt where retryCount > 0 must count toward "Needed retries".
    func test_retriedCount_includesSkippedAttemptsWithRetries() {
        let view = makeView(attempts: [makeAttempt(outcome: .skipped, retryCount: 1)])
        XCTAssertEqual(view.retriedCount, 1)
    }

    /// A passed-after-retry attempt must still count.
    func test_retriedCount_includesPassedAfterRetry() {
        let view = makeView(attempts: [makeAttempt(outcome: .passedAfterRetry, retryCount: 1)])
        XCTAssertEqual(view.retriedCount, 1)
    }

    /// A clean pass with no retries must not count.
    func test_retriedCount_excludesCleanPass() {
        let view = makeView(attempts: [makeAttempt(outcome: .passed, retryCount: 0)])
        XCTAssertEqual(view.retriedCount, 0)
    }

    /// A skipped attempt with no retries must not count.
    func test_retriedCount_excludesSkippedWithNoRetries() {
        let view = makeView(attempts: [makeAttempt(outcome: .skipped, retryCount: 0)])
        XCTAssertEqual(view.retriedCount, 0)
    }
}
