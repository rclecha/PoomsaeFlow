import Foundation

enum SessionScope: Codable, Equatable {
    case single(UUID)
    case fullSet
    case custom([UUID])
    case pinned
}
