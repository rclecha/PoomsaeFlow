import Foundation

struct VideoResource: Codable, Hashable {
    let url: URL
    let source: String?
    let isPrimary: Bool
}
