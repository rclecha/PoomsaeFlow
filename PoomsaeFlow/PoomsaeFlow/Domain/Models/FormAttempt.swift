import Foundation
import SwiftData

/// `.retry` is intentionally excluded from persistence. It signals that the user wants
/// another attempt within the same session — a transient UI state, not a historical fact.
/// Writing it to SwiftData would corrupt history queries that expect only terminal outcomes.
enum AttemptOutcome: String, Codable {
    case passed
    case passedAfterRetry
    case skipped
    /// Transient — never written to SwiftData. Resolved to a terminal outcome before save.
    case retry
}

@Model
final class FormAttempt {
    var id: UUID
    var sessionID: UUID
    var formID: UUID
    /// Always a locally generated anonymous UUID in v1. The field exists so the schema
    /// is ready for a future accounts feature without a migration that adds a nullable column.
    var userID: UUID
    var attemptedAt: Date
    var outcome: AttemptOutcome
    var retryCount: Int
    var createdAt: Date
    /// Mirrors createdAt on init because FormAttempt is effectively immutable — once
    /// recorded, an attempt is never edited. The field exists for schema consistency with
    /// all other persistent types so tooling and future migrations have a uniform shape.
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
