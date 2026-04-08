import Foundation
import Observation

/// Bridges user preferences and the form catalog to the home/browse UI.
///
/// Owns no session state — that belongs to SessionController. HomeViewModel is solely
/// responsible for reading and writing the four preference slices (active profile, belt,
/// session defaults, pinned forms) and computing the eligible form list from them.
/// All repository calls are synchronous (UserDefaults-backed), so init loads eagerly
/// rather than async-on-appear.
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    private let userPrefs: UserPrefsRepository
    private let formRepo: FormRepository

    // MARK: - State

    private(set) var activeProfile: DojangProfile
    private(set) var activeBeltLevel: BeltLevel
    private(set) var sessionDefaults: SessionDefaults
    private(set) var pinnedForms: PinnedForms

    /// Recomputed whenever `activeProfile`, `activeBeltLevel`, or `sessionDefaults` changes.
    /// FormFilterService is pure and cheap, so no caching is needed.
    var eligibleForms: [TKDForm] {
        FormFilterService.eligibleForms(
            userBelt: activeBeltLevel,
            profile: activeProfile,
            allForms: formRepo.all,
            enabledFamilies: sessionDefaults.enabledFamilies
        )
    }

    // MARK: - Init

    init(userPrefs: UserPrefsRepository, formRepo: FormRepository) {
        self.userPrefs = userPrefs
        self.formRepo = formRepo

        // Fall back to Sparta TKD so the home screen is populated on first launch
        // before onboarding runs. HomeViewModel is the only place outside the data layer
        // that names a preset — it is the bootstrap boundary, not a business rule.
        let profile = userPrefs.activeProfile ?? BeltSystemPreset.spartaTKD.makeProfile()

        // Resolve stored belt by ID; fall back to the first belt in the profile.
        // All concrete presets (World Taekwondo, Sparta TKD) have ≥1 belt, so force-
        // unwrapping first is safe. The custom preset is unreachable in v1 because
        // onboarding never persists it as the active profile.
        let storedBeltID = userPrefs.trainingProfile?.selectedBeltLevelID
        let belt = profile.beltLevels.first { $0.id == storedBeltID }
                ?? profile.beltLevels.first!

        let defaults = userPrefs.sessionDefaults ?? SessionDefaults(
            defaultOrder: .sequential,
            enabledFamilies: FormFamily.allCases,
            createdAt: Date(),
            updatedAt: Date()
        )

        let pinned = userPrefs.pinnedForms ?? PinnedForms(
            formIDs: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        self.activeProfile = profile
        self.activeBeltLevel = belt
        self.sessionDefaults = defaults
        self.pinnedForms = pinned
    }

    // MARK: - Mutations

    /// Switches the active dojang profile and resets belt to the first in the new profile
    /// so the stored belt ID is always valid for the current profile's ladder.
    func saveProfile(_ profile: DojangProfile) {
        let now = Date()
        let newBelt = profile.beltLevels.first ?? activeBeltLevel
        activeProfile = profile
        activeBeltLevel = newBelt
        userPrefs.save(profile)
        userPrefs.save(TrainingProfile(
            selectedProfileID: profile.id,
            selectedBeltLevelID: newBelt.id,
            createdAt: userPrefs.trainingProfile?.createdAt ?? now,
            updatedAt: now
        ))
    }

    func saveBeltLevel(_ beltLevel: BeltLevel) {
        let now = Date()
        activeBeltLevel = beltLevel
        userPrefs.save(TrainingProfile(
            selectedProfileID: activeProfile.id,
            selectedBeltLevelID: beltLevel.id,
            createdAt: userPrefs.trainingProfile?.createdAt ?? now,
            updatedAt: now
        ))
    }

    func saveSessionDefaults(_ defaults: SessionDefaults) {
        sessionDefaults = defaults
        userPrefs.save(defaults)
    }

    /// Builds a ready-to-start `PracticeSession` by re-filtering eligible forms for
    /// the given family selection and delegating to SessionBuilder.
    /// Lives in the ViewModel so views never call FormFilterService or SessionBuilder directly.
    func buildSession(scope: SessionScope, order: SessionOrder, families: [FormFamily]) -> PracticeSession {
        let forms = FormFilterService.eligibleForms(
            userBelt: activeBeltLevel,
            profile: activeProfile,
            allForms: formRepo.all,
            enabledFamilies: families
        )
        return SessionBuilder.buildSession(
            scope: scope,
            order: order,
            eligibleForms: forms,
            pinnedIDs: pinnedForms.formIDs
        )
    }
}
