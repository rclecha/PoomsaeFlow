import Foundation

struct PinnedForms: Codable {
    let formIDs: [UUID]
    let createdAt: Date
    let updatedAt: Date
}
