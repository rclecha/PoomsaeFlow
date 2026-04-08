import Foundation

/// The protocol seam exists now — even though both methods are no-ops in v1 — so that
/// `SessionController` can call `save()` without knowing it's a stub. In v2, SwiftData
/// history queries power the weakness engine (surfacing forms the user struggles with).
/// Swapping in a real implementation then requires only a new conforming type, not
/// changes across every call site that records an attempt.
protocol SessionRepository {
    func save(_ attempts: [FormAttempt])
    func fetchHistory(for formID: UUID) -> [FormAttempt]
}

struct DefaultSessionRepository: SessionRepository {
    /// v1 stub — SwiftData persistence not yet implemented.
    func save(_ attempts: [FormAttempt]) {}

    /// v1 stub — returns empty; weakness engine ships in v2.
    func fetchHistory(for formID: UUID) -> [FormAttempt] { [] }
}
