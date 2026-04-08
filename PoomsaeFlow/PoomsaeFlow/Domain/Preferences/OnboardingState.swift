import Foundation

struct OnboardingState: Codable {
    let isOnboarded: Bool
    let hasSeenPinHint: Bool
    let createdAt: Date
    let updatedAt: Date
}
