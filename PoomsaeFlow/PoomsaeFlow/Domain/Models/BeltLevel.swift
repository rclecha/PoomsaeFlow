import Foundation

struct BeltLevel: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let canonical: CanonicalBelt
    let displayOrder: Int
    let colorHex: String
    let isDefault: Bool
    let createdAt: Date
    let updatedAt: Date
}
