import Foundation
import Observation

/// Owns state for the filter/settings sheet.
///
/// Kept separate from HomeViewModel for two reasons:
/// 1. Lifetime — this object is created when the sheet opens and discarded when it
///    closes. HomeViewModel lives for the full screen lifetime. Merging them would
///    force HomeViewModel to manage transient sheet state it doesn't own.
/// 2. Cohesion — filter state (which families are enabled, which profile to select)
///    is a self-contained concern. Adding it to HomeViewModel would make that class
///    a god object responsible for both browsing and filtering.
@Observable
final class FilterViewModel {

    // MARK: - Dependencies

    private let userPrefs: UserPrefsRepository

    // MARK: - State

    private(set) var enabledFamilies: [FormFamily]

    // MARK: - Init

    init(userPrefs: UserPrefsRepository) {
        self.userPrefs = userPrefs
        enabledFamilies = userPrefs.sessionDefaults?.enabledFamilies ?? FormFamily.allCases
    }

    // MARK: - Mutations

    /// Adds `family` if absent, removes it if present, then persists the updated list.
    func toggleFamily(_ family: FormFamily) {
        if let index = enabledFamilies.firstIndex(of: family) {
            enabledFamilies.remove(at: index)
        } else {
            enabledFamilies.append(family)
        }
        persistSessionDefaults()
    }

    // MARK: - Private

    private func persistSessionDefaults() {
        let now = Date()
        userPrefs.save(SessionDefaults(
            defaultOrder: userPrefs.sessionDefaults?.defaultOrder ?? .sequential,
            enabledFamilies: enabledFamilies,
            createdAt: userPrefs.sessionDefaults?.createdAt ?? now,
            updatedAt: now
        ))
    }
}
