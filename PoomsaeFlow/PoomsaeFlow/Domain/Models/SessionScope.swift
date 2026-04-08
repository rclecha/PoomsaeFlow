import Foundation

enum SessionScope: Codable {
    case single(UUID)
    case fullSet
    case custom([UUID])
    case pinned
}
