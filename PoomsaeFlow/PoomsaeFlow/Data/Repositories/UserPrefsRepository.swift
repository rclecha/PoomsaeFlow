import Foundation

/// Preferences are split into four independent Codable structs rather than one object
/// because each slice has a different update cadence and ownership. `TrainingProfile`
/// changes when the user switches dojang or belt. `SessionDefaults` changes in settings.
/// `PinnedForms` changes during browsing. `OnboardingState` is written once. A single
/// god object would cause every reader to decode fields they don't need, and every writer
/// to risk overwriting another slice's concurrent change.
protocol UserPrefsRepository {
    var trainingProfile: TrainingProfile? { get }
    func save(_ trainingProfile: TrainingProfile)

    var sessionDefaults: SessionDefaults? { get }
    func save(_ sessionDefaults: SessionDefaults)

    var pinnedForms: PinnedForms? { get }
    func save(_ pinnedForms: PinnedForms)

    var onboardingState: OnboardingState? { get }
    func save(_ onboardingState: OnboardingState)

    /// The active `DojangProfile` is stored as encoded `Data` rather than by its UUID
    /// alone because profiles created from `BeltSystemPreset` are value types with no
    /// separate persistence layer — the full value must be round-tripped.
    var activeProfile: DojangProfile? { get }
    func save(_ activeProfile: DojangProfile)
}

struct DefaultUserPrefsRepository: UserPrefsRepository {
    private let defaults: UserDefaults
    private let encoder  = JSONEncoder()
    private let decoder  = JSONDecoder()

    init() {
        self.defaults = .standard
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - Keys

    private enum Key {
        static let trainingProfile = "com.ryan.PoomsaeFlow.trainingProfile"
        static let sessionDefaults = "com.ryan.PoomsaeFlow.sessionDefaults"
        static let pinnedForms     = "com.ryan.PoomsaeFlow.pinnedForms"
        static let onboardingState = "com.ryan.PoomsaeFlow.onboardingState"
        static let activeProfile   = "com.ryan.PoomsaeFlow.activeProfile"
    }

    // MARK: - TrainingProfile

    var trainingProfile: TrainingProfile? {
        decode(TrainingProfile.self, forKey: Key.trainingProfile)
    }

    func save(_ trainingProfile: TrainingProfile) {
        encode(trainingProfile, forKey: Key.trainingProfile)
    }

    // MARK: - SessionDefaults

    var sessionDefaults: SessionDefaults? {
        decode(SessionDefaults.self, forKey: Key.sessionDefaults)
    }

    func save(_ sessionDefaults: SessionDefaults) {
        encode(sessionDefaults, forKey: Key.sessionDefaults)
    }

    // MARK: - PinnedForms

    var pinnedForms: PinnedForms? {
        decode(PinnedForms.self, forKey: Key.pinnedForms)
    }

    func save(_ pinnedForms: PinnedForms) {
        encode(pinnedForms, forKey: Key.pinnedForms)
    }

    // MARK: - OnboardingState

    var onboardingState: OnboardingState? {
        decode(OnboardingState.self, forKey: Key.onboardingState)
    }

    func save(_ onboardingState: OnboardingState) {
        encode(onboardingState, forKey: Key.onboardingState)
    }

    // MARK: - ActiveProfile

    var activeProfile: DojangProfile? {
        decode(DojangProfile.self, forKey: Key.activeProfile)
    }

    func save(_ activeProfile: DojangProfile) {
        encode(activeProfile, forKey: Key.activeProfile)
    }

    // MARK: - Helpers

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
