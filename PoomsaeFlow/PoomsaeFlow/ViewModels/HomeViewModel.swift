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

    /// Non-nil when a school switch has been proposed but requires user confirmation
    /// because the new catalog would orphan one or more currently-pinned forms.
    /// Views observe this and present a warning sheet when it becomes non-nil.
    private(set) var pendingSchoolSwitch: PendingSchoolSwitch?

    // MARK: - PendingSchoolSwitch

    struct PendingSchoolSwitch {
        let profile: DojangProfile
        let belt: BeltLevel
        let orphanedForms: [TKDForm]
    }

    // MARK: - Computed — eligible forms

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

    /// Forms whose `introducedAt` belt exactly matches the trainee's current canonical belt.
    /// Derived from `eligibleForms` so the profile catalog gate and enabled-families filter
    /// are already applied — only the "exactly this belt" refinement is added here.
    var formsIntroducedAtCurrentBelt: [TKDForm] {
        eligibleForms.filter { $0.introducedAt == activeBeltLevel.canonical }
    }

    // MARK: - Computed — pinned forms

    /// Pinned forms resolved from IDs to full TKDForm values, preserving insertion order.
    /// UUIDs that no longer exist in the catalog are silently dropped.
    var resolvedPinnedForms: [TKDForm] {
        let catalog = formsByID
        return pinnedForms.formIDs.compactMap { catalog[$0] }
    }

    /// Forms eligible for the Form Browser: catalog-scoped and belt-capped, but with no
    /// family filter applied (Form Browser shows all families). Already-pinned forms are
    /// included so the browser can show their checked/disabled state.
    var browsableForms: [TKDForm] {
        FormFilterService.eligibleForms(
            userBelt: activeBeltLevel,
            profile: activeProfile,
            allForms: formRepo.all,
            enabledFamilies: nil
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
        precondition(
            !profile.beltLevels.isEmpty,
            "Active profile has no belt levels. BeltSystemPreset.custom is not supported in v1 and must never be stored as the active profile."
        )
        let belt = profile.beltLevels.first { $0.id == storedBeltID }
                ?? profile.beltLevels.first!

        let defaults = userPrefs.sessionDefaults ?? SessionDefaults(
            defaultOrder: .sequential,
            enabledFamilies: FormFamily.allCases,
            createdAt: Date(),
            updatedAt: Date()
        )

        let pinned = userPrefs.pinnedForms ?? .empty

        self.activeProfile = profile
        self.activeBeltLevel = belt
        self.sessionDefaults = defaults
        self.pinnedForms = pinned
    }

    // MARK: - Profile mutations

    /// Proposes switching to a new school profile at a specific belt.
    ///
    /// If the new profile's catalog (`formIDs`) would orphan any currently-pinned forms,
    /// this method sets `pendingSchoolSwitch` and returns without saving — the caller
    /// is responsible for observing that state and presenting a warning before confirming.
    /// If no orphans exist (or the catalog is unrestricted), the switch is applied immediately.
    func switchProfile(profile: DojangProfile, belt: BeltLevel) {
        let orphans = orphanedForms(for: profile)
        if orphans.isEmpty {
            applyProfileChange(profile: profile, belt: belt)
        } else {
            pendingSchoolSwitch = PendingSchoolSwitch(
                profile: profile,
                belt: belt,
                orphanedForms: orphans
            )
        }
    }

    /// Completes a pending school switch: drops the orphaned pins, applies the profile
    /// change, and clears `pendingSchoolSwitch`. No-op if no switch is pending.
    func confirmSchoolSwitch() {
        guard let pending = pendingSchoolSwitch else { return }
        let orphanIDs = Set(pending.orphanedForms.map { $0.id })
        let updated = pinnedForms.removingAll(orphanIDs)
        pinnedForms = updated
        userPrefs.save(updated)
        applyProfileChange(profile: pending.profile, belt: pending.belt)
        pendingSchoolSwitch = nil
    }

    /// Aborts a pending school switch, leaving the current profile and pins intact.
    func cancelSchoolSwitch() {
        pendingSchoolSwitch = nil
    }

    func saveBeltLevel(_ beltLevel: BeltLevel) {
        activeBeltLevel = beltLevel
        userPrefs.save(makeTrainingProfile(belt: beltLevel))
    }

    func saveSessionDefaults(_ defaults: SessionDefaults) {
        sessionDefaults = defaults
        userPrefs.save(defaults)
    }

    /// Re-reads pinned forms from the repository so HomeView reflects changes made
    /// during a session (e.g. the user tapped the pin button in SessionView).
    func reloadPinnedForms() {
        pinnedForms = userPrefs.pinnedForms ?? .empty
    }

    // MARK: - Pin mutations

    func pinForm(_ id: UUID) {
        pinnedForms = pinnedForms.adding(id)
        userPrefs.save(pinnedForms)
    }

    func unpinForm(_ id: UUID) {
        pinnedForms = pinnedForms.removing(id)
        userPrefs.save(pinnedForms)
    }

    func reorderPinnedForms(fromOffsets: IndexSet, toOffset: Int) {
        pinnedForms = pinnedForms.reordering(fromOffsets: fromOffsets, toOffset: toOffset)
        userPrefs.save(pinnedForms)
    }

    // MARK: - Session building

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

    // MARK: - Private

    private func makeTrainingProfile(belt: BeltLevel) -> TrainingProfile {
        let now = Date()
        return TrainingProfile(
            selectedProfileID: activeProfile.id,
            selectedBeltLevelID: belt.id,
            createdAt: userPrefs.trainingProfile?.createdAt ?? now,
            updatedAt: now
        )
    }

    private var formsByID: [UUID: TKDForm] {
        Dictionary(uniqueKeysWithValues: formRepo.all.map { ($0.id, $0) })
    }

    private func applyProfileChange(profile: DojangProfile, belt: BeltLevel) {
        activeProfile = profile
        activeBeltLevel = belt
        userPrefs.save(profile)
        userPrefs.save(makeTrainingProfile(belt: belt))
    }

    /// Returns the pinned forms that would be orphaned by switching to `profile`.
    /// Returns empty if the new catalog is unrestricted (formIDs == nil).
    private func orphanedForms(for profile: DojangProfile) -> [TKDForm] {
        guard let allowedIDs = profile.formIDs else { return [] }
        let catalog = formsByID
        return pinnedForms.formIDs
            .filter { !allowedIDs.contains($0) }
            .compactMap { catalog[$0] }
    }
}
