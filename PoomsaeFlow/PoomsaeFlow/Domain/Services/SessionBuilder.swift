import Foundation

/// Pure session factory — no state, no side effects.
/// Resolves a `SessionScope` to a concrete form list, applies ordering, and
/// wraps the result in a `PracticeSession` ready to hand to `SessionController`.
enum SessionBuilder {

    /// Builds a ready-to-start `PracticeSession` from the given scope and preferences.
    ///
    /// - Parameters:
    ///   - scope: Determines which subset of `eligibleForms` to include.
    ///   - order: Applied after scope resolution — sequential sorts by belt rank then family,
    ///     randomized shuffles without replacement.
    ///   - eligibleForms: Pre-filtered by `FormFilterService`; this function does not
    ///     re-apply belt or family rules.
    ///   - pinnedIDs: Used only when `scope == .pinned`; ignored otherwise.
    nonisolated static func buildSession(
        scope: SessionScope,
        order: SessionOrder,
        eligibleForms: [TKDForm],
        pinnedIDs: [UUID]
    ) -> PracticeSession {
        let resolved = resolve(scope: scope, eligibleForms: eligibleForms, pinnedIDs: pinnedIDs)
        let queue    = ordered(resolved, by: order)
        return PracticeSession(id: UUID(), scope: scope, order: order,
                               queue: queue, currentIndex: 0)
    }

    // MARK: - Private

    private nonisolated static func resolve(
        scope: SessionScope,
        eligibleForms: [TKDForm],
        pinnedIDs: [UUID]
    ) -> [TKDForm] {
        switch scope {
        case .single(let id):
            return eligibleForms.filter { $0.id == id }

        case .fullSet:
            return eligibleForms

        case .custom(let ids):
            // Preserve the order from eligibleForms rather than the UUID list order
            // so that sequential sessions have a predictable, belt-ordered sequence.
            let requested = Set(ids)
            return eligibleForms.filter { requested.contains($0.id) }

        case .pinned:
            let pinned = Set(pinnedIDs)
            return eligibleForms.filter { pinned.contains($0.id) }
        }
    }

    private nonisolated static func ordered(
        _ forms: [TKDForm],
        by order: SessionOrder
    ) -> [TKDForm] {
        switch order {
        case .sequential:
            // Primary: introducedAt.order ascending (belt rank).
            // Tiebreaker: FormFamily.allCases position — Keecho, Taegeuk, Palgwe, Poom, Black Belt.
            let familyRank = Dictionary(
                uniqueKeysWithValues: FormFamily.allCases.enumerated().map { ($1, $0) }
            )
            return forms.sorted {
                let beltDiff = $0.introducedAt.order - $1.introducedAt.order
                if beltDiff != 0 { return beltDiff < 0 }
                return (familyRank[$0.family] ?? 0) < (familyRank[$1.family] ?? 0)
            }
        case .randomized:
            return forms.shuffled()
        }
    }
}
