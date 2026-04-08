import Foundation

struct SessionDefaults: Codable {
    let defaultOrder: SessionOrder
    let enabledFamilies: [FormFamily]
    let createdAt: Date
    let updatedAt: Date
}
