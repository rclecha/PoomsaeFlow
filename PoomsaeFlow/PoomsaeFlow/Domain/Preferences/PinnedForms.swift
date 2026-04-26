import Foundation

struct PinnedForms: Codable {
    let formIDs: [UUID]
    let createdAt: Date
    let updatedAt: Date

    /// Convenience factory for an empty pin list with timestamps set to now.
    static var empty: PinnedForms {
        PinnedForms(formIDs: [], createdAt: Date(), updatedAt: Date())
    }

    // MARK: - Helpers

    /// Returns a new PinnedForms with `id` appended, or the receiver unchanged if already present.
    func adding(_ id: UUID) -> PinnedForms {
        guard !formIDs.contains(id) else { return self }
        return PinnedForms(formIDs: formIDs + [id], createdAt: createdAt, updatedAt: Date())
    }

    /// Returns a new PinnedForms with all IDs in `ids` removed in a single pass.
    func removingAll(_ ids: Set<UUID>) -> PinnedForms {
        let updated = formIDs.filter { !ids.contains($0) }
        guard updated.count != formIDs.count else { return self }
        return PinnedForms(formIDs: updated, createdAt: createdAt, updatedAt: Date())
    }

    /// Returns a new PinnedForms with `id` removed. No-op if `id` is not present.
    func removing(_ id: UUID) -> PinnedForms {
        let updated = formIDs.filter { $0 != id }
        guard updated.count != formIDs.count else { return self }
        return PinnedForms(formIDs: updated, createdAt: createdAt, updatedAt: Date())
    }

    /// Returns a new PinnedForms with the `formIDs` array reordered using SwiftUI `.onMove` offsets.
    /// Pure Swift — no SwiftUI import required.
    func reordering(fromOffsets: IndexSet, toOffset: Int) -> PinnedForms {
        var updated = formIDs
        let items = fromOffsets.sorted().map { updated[$0] }
        for index in fromOffsets.sorted().reversed() {
            updated.remove(at: index)
        }
        let adjustedOffset = toOffset - fromOffsets.filter { $0 < toOffset }.count
        updated.insert(contentsOf: items, at: adjustedOffset)
        return PinnedForms(formIDs: updated, createdAt: createdAt, updatedAt: Date())
    }
}
