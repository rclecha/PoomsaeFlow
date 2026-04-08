import Foundation

struct TKDForm: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let koreanName: String?
    let family: FormFamily
    let introducedAt: CanonicalBelt
    let videos: [VideoResource]
    let notes: String?
}
