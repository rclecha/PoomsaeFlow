import Foundation
import SwiftData

/// Transient outcome used at runtime; only `passed`, `passedAfterRetry`, and `skipped`
/// are persisted to SwiftData.
enum AttemptOutcome: String, Codable {
    case passed
    case passedAfterRetry
    case skipped
    /// Transient — never written to SwiftData.
    case retry
}

@Model
final class FormAttempt {
    var id: UUID
    var sessionID: UUID
    var formID: UUID
    var userID: UUID
    var attemptedAt: Date
    var outcome: AttemptOutcome
    var retryCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        formID: UUID,
        userID: UUID,
        attemptedAt: Date = Date(),
        outcome: AttemptOutcome,
        retryCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.formID = formID
        self.userID = userID
        self.attemptedAt = attemptedAt
        self.outcome = outcome
        self.retryCount = retryCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
