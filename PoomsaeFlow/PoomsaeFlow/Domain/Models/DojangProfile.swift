import Foundation

/// The primary extensibility seam for multi-school support.
///
/// All service-layer types (`FormFilterService`, `SessionBuilder`) consume `DojangProfile`
/// exclusively — they never reference `BeltSystemPreset`. This means new school configurations
/// can be added without touching service logic: create a profile, hand it to the services.
struct DojangProfile: Identifiable, Codable {
    let id: UUID
    let name: String
    let beltLevels: [BeltLevel]
    /// `Set` rather than `Array` because membership tests dominate over iteration, and
    /// duplicates are meaningless. `nil` is a deliberate sentinel meaning "no filter —
    /// show every form in the catalog", which is different from an empty set (no forms).
    let formIDs: Set<UUID>?
    let createdAt: Date
    let updatedAt: Date
}
