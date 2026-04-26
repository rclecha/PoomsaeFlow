import Foundation

protocol UserIdentityProvider {
    var userID: UUID { get }
}

/// Generates a stable anonymous UUID on first access and stores it in UserDefaults
/// so every session in the app shares the same local identity across launches.
struct AnonymousIdentityProvider: UserIdentityProvider {
    private static let key = "com.ryan.PoomsaeFlow.anonymousUserID"

    var userID: UUID {
        if let stored = UserDefaults.standard.string(forKey: Self.key),
           let id = UUID(uuidString: stored) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: Self.key)
        return id
    }
}
