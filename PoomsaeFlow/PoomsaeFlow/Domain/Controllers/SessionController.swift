import Foundation
import Observation

/// Owns all mutable session state and outcome logic for an active practice session.
///
/// Implemented as a class (not a struct) for two reasons:
/// 1. `@Observable` requires a reference type — the macro injects a per-instance
///    observation registrar that SwiftUI holds a reference to.
/// 2. Session state must mutate in place: views, the session queue, and the attempts
///    log all need to observe the *same* object, which only reference semantics provides.
@Observable
final class SessionController {

    // MARK: - Init

    /// Production init — uses `AnonymousIdentityProvider` for a stable per-device user ID.
    init(session: PracticeSession) {
        self.session = session
        self.userID = AnonymousIdentityProvider().userID
    }

    /// Test init — accepts an explicit `userID` so tests can assert on attempt identity.
    init(session: PracticeSession, userID: UUID) {
        self.session = session
        self.userID = userID
    }

    // MARK: - Derived State

    var currentForm: TKDForm? { session.currentForm }

    var isComplete: Bool { session.isComplete }

    /// Linear 0.0 → 1.0 as forms are completed. Returns 0.0 for an empty queue rather
    /// than 1.0 to avoid a misleading "100% complete" flash before the controller is used.
    var progress: Double {
        guard !session.queue.isEmpty else { return 0 }
        return Double(session.currentIndex) / Double(session.queue.count)
    }

    // MARK: - Outcome Recording

    private(set) var session: PracticeSession
    private(set) var attempts: [FormAttempt] = []

    /// Tracks consecutive retries for the current form so `recordOutcome` can resolve
    /// `.passed` → `.passedAfterRetry` automatically. Resets to 0 after every terminal
    /// outcome so each new form starts fresh — a retry on form N must not bleed into form N+1.
    private(set) var retryCount: Int = 0

    /// Generated once at controller creation and reused for every `FormAttempt` in this
    /// session. A new UUID per session is correct for v1 (all users are anonymous); a single
    /// stable UUID per session means all attempts in one session share an identity that can
    /// be correlated later without requiring a real account system.
    private let userID: UUID

    /// Records the outcome of the current form and advances the session if the outcome
    /// is terminal (anything other than `.retry`).
    ///
    /// `.passedAfterRetry` is resolved here — not by the caller — because only this object
    /// knows how many retries preceded the pass. Pushing that logic to call sites would
    /// require every caller to track `retryCount`, violating the single-owner principle.
    func recordOutcome(_ outcome: TransientOutcome) {
        guard let form = currentForm else { return }

        switch outcome {
        case .retry:
            retryCount += 1

        case .passed, .skipped:
            let persistedOutcome: AttemptOutcome = (outcome == .passed && retryCount > 0)
                ? .passedAfterRetry : (outcome == .passed ? .passed : .skipped)
            let now = Date()
            let attempt = FormAttempt(
                sessionID: session.id,
                formID: form.id,
                userID: userID,
                attemptedAt: now,
                outcome: persistedOutcome,
                retryCount: retryCount,
                createdAt: now,
                updatedAt: now
            )
            attempts.append(attempt)
            retryCount = 0
            session.currentIndex += 1
        }
    }
}

