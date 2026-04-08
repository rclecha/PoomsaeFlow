import Foundation

struct TrainingProfile: Codable {
    let selectedProfileID: UUID
    let selectedBeltLevelID: UUID
    let createdAt: Date
    let updatedAt: Date
}
