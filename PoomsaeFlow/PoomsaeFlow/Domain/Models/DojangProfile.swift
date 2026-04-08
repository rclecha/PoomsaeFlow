import Foundation

struct DojangProfile: Identifiable, Codable {
    let id: UUID
    let name: String
    let beltLevels: [BeltLevel]
    /// nil means "all forms in catalog" — no filtering applied
    let formIDs: Set<UUID>?
    let createdAt: Date
    let updatedAt: Date
}
