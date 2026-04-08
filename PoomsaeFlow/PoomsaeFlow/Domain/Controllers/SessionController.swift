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

    /// - Parameter session: A fully resolved `PracticeSession` from `SessionBuilder`.
    ///   The controller takes ownership; nothing outside should mutate the session after this.
    init(session: PracticeSession) {
        self.session = session
    }

    // MARK: - Derived State

    /// `nil` when the session is complete. Uses the private safe subscript rather than a
    /// raw index so there is no possible out-of-bounds crash if state ever diverges.
    var currentForm: TKDForm? { session.queue[safe: session.currentIndex] }

    var isComplete: Bool { session.currentIndex >= session.queue.count }

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
    private let userID: UUID = UUID()

    /// Records the outcome of the current form and advances the session if the outcome
    /// is terminal (anything other than `.retry`).
    ///
    /// `.passedAfterRetry` is resolved here — not by the caller — because only this object
    /// knows how many retries preceded the pass. Pushing that logic to call sites would
    /// require every caller to track `retryCount`, violating the single-owner principle.
    func recordOutcome(_ outcome: AttemptOutcome) {
        guard let form = currentForm else { return }

        switch outcome {
        case .retry:
            retryCount += 1

        case .passed, .passedAfterRetry, .skipped:
            let resolvedOutcome: AttemptOutcome = (outcome == .passed && retryCount > 0)
                ? .passedAfterRetry : outcome
            let now = Date()
            let attempt = FormAttempt(
                sessionID: session.id,
                formID: form.id,
                userID: userID,
                attemptedAt: now,
                outcome: resolvedOutcome,
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

// MARK: - Array safe subscript

/// Defined here (not globally) because this is the only file that needs it.
/// `PracticeSession.currentForm` uses explicit bounds-checking inline; this subscript
/// is the cleaner form for `SessionController`'s use at the call site.
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
