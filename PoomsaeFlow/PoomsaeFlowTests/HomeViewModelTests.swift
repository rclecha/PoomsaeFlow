import XCTest
@testable import PoomsaeFlow

final class HomeViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private func makeBeltLevel(canonical: CanonicalBelt, displayOrder: Int = 0) -> BeltLevel {
        BeltLevel(id: UUID(), name: "\(canonical)", canonical: canonical,
                  displayOrder: displayOrder, colorHex: "#000000", isDefault: true,
                  createdAt: .now, updatedAt: .now)
    }

    private func makeForm(id: UUID = UUID(), family: FormFamily,
                          introducedAt: CanonicalBelt) -> TKDForm {
        TKDForm(id: id, name: "Form \(introducedAt)", koreanName: nil,
                family: family, introducedAt: introducedAt, videos: [], notes: nil)
    }

    private func makeVM(belt: BeltLevel, forms: [TKDForm]) -> HomeViewModel {
        let profile = DojangProfile(
            id: UUID(), name: "Test", beltLevels: [belt],
            formIDs: nil, createdAt: .now, updatedAt: .now
        )
        let userPrefs = StubUserPrefsRepository(profile: profile, beltID: belt.id)
        let formRepo = StubFormRepository(forms: forms)
        return HomeViewModel(userPrefs: userPrefs, formRepo: formRepo)
    }

    // MARK: - formsIntroducedAtCurrentBelt

    /// Black belt with no forms in the catalog introduced exactly at black → empty result.
    func test_blackBelt_noFormsAtBlack_returnsEmpty() {
        let belt = makeBeltLevel(canonical: .black)
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .white),
            makeForm(family: .taegeuk, introducedAt: .yellow),
            makeForm(family: .taegeuk, introducedAt: .redAdv),
        ]
        let vm = makeVM(belt: belt, forms: forms)
        XCTAssertTrue(vm.formsIntroducedAtCurrentBelt.isEmpty)
    }

    /// Orange belt with catalog spanning white through green: only orange-introduced
    /// forms are returned, not those below or above.
    func test_orangeBelt_returnsOnlyFormsIntroducedAtOrange() {
        let belt = makeBeltLevel(canonical: .orange)
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .white),
            makeForm(family: .taegeuk, introducedAt: .yellow),
            makeForm(family: .taegeuk, introducedAt: .orange),
            makeForm(family: .keecho,  introducedAt: .orange),
            makeForm(family: .taegeuk, introducedAt: .green),   // above belt — excluded
        ]
        let vm = makeVM(belt: belt, forms: forms)
        let result = vm.formsIntroducedAtCurrentBelt
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.introducedAt == .orange })
    }

    /// Red-advanced belt: the result contains exactly the redAdv forms, identified
    /// by their IDs, with no below-belt or above-belt forms included.
    func test_redAdvBelt_returnsExactlyRedAdvForms() {
        let belt = makeBeltLevel(canonical: .redAdv)
        let redAdvID1 = UUID()
        let redAdvID2 = UUID()
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .white),
            makeForm(family: .taegeuk, introducedAt: .red),
            makeForm(id: redAdvID1, family: .taegeuk, introducedAt: .redAdv),
            makeForm(id: redAdvID2, family: .palgwe,  introducedAt: .redAdv),
            makeForm(family: .taegeuk, introducedAt: .black),   // above belt — excluded
        ]
        let vm = makeVM(belt: belt, forms: forms)
        let result = vm.formsIntroducedAtCurrentBelt
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.introducedAt == .redAdv })
        XCTAssertTrue(result.contains { $0.id == redAdvID1 })
        XCTAssertTrue(result.contains { $0.id == redAdvID2 })
    }

    /// Empty form catalog at any belt level → empty belt forms.
    func test_emptyFormCatalog_returnsEmpty() {
        let belt = makeBeltLevel(canonical: .orange)
        let vm = makeVM(belt: belt, forms: [])
        XCTAssertTrue(vm.formsIntroducedAtCurrentBelt.isEmpty)
    }
}

// MARK: - switchProfile / orphan detection

final class HomeViewModelSchoolSwitchTests: XCTestCase {

    private func makeBelt(_ canonical: CanonicalBelt, id: UUID = UUID()) -> BeltLevel {
        BeltLevel(id: id, name: "\(canonical)", canonical: canonical,
                  displayOrder: 0, colorHex: "#000000", isDefault: true,
                  createdAt: .now, updatedAt: .now)
    }

    private func makeForm(id: UUID = UUID(), family: FormFamily = .taegeuk,
                          introducedAt: CanonicalBelt = .white) -> TKDForm {
        TKDForm(id: id, name: "Form \(id.uuidString.prefix(4))", koreanName: nil,
                family: family, introducedAt: introducedAt, videos: [], notes: nil)
    }

    private func makeVM(
        pinnedIDs: [UUID] = [],
        profileFormIDs: Set<UUID>? = nil,
        forms: [TKDForm] = []
    ) -> (HomeViewModel, SpyUserPrefsRepository) {
        let belt = makeBelt(.white)
        let profile = DojangProfile(
            id: UUID(), name: "Test", beltLevels: [belt],
            formIDs: profileFormIDs, createdAt: .now, updatedAt: .now
        )
        let pinned = PinnedForms(formIDs: pinnedIDs, createdAt: .now, updatedAt: .now)
        let spy = SpyUserPrefsRepository(profile: profile, beltID: belt.id, pinnedForms: pinned)
        let formRepo = StubFormRepository(forms: forms)
        return (HomeViewModel(userPrefs: spy, formRepo: formRepo), spy)
    }

    // MARK: - Orphan detection — nil formIDs

    /// Switching to a profile with nil formIDs (unrestricted catalog) never produces orphans,
    /// even when the user has pinned forms.
    func test_switchProfile_nilFormIDs_noOrphans_appliesImmediately() {
        let formID = UUID()
        let form = makeForm(id: formID)
        let (vm, spy) = makeVM(pinnedIDs: [formID], forms: [form])
        let belt = makeBelt(.yellow)
        let newProfile = DojangProfile(
            id: UUID(), name: "New", beltLevels: [belt],
            formIDs: nil, createdAt: .now, updatedAt: .now
        )

        vm.switchProfile(profile: newProfile, belt: belt)

        XCTAssertNil(vm.pendingSchoolSwitch, "nil formIDs must never pend — no orphans possible")
        XCTAssertEqual(vm.activeProfile.id, newProfile.id)
        XCTAssertTrue(spy.savedProfiles.contains { $0.id == newProfile.id })
    }

    // MARK: - Orphan detection — non-nil formIDs, no overlap

    /// All pinned IDs outside the new catalog → orphans → pendingSchoolSwitch set, save NOT called.
    func test_switchProfile_allPinsOrphaned_setsPending() {
        let pinnedID = UUID()
        let pinnedForm = makeForm(id: pinnedID)
        let (vm, spy) = makeVM(pinnedIDs: [pinnedID], forms: [pinnedForm])
        let belt = makeBelt(.yellow)
        let unrelatedID = UUID()
        let newProfile = DojangProfile(
            id: UUID(), name: "New", beltLevels: [belt],
            formIDs: [unrelatedID], createdAt: .now, updatedAt: .now
        )

        vm.switchProfile(profile: newProfile, belt: belt)

        XCTAssertNotNil(vm.pendingSchoolSwitch)
        XCTAssertEqual(vm.pendingSchoolSwitch?.orphanedForms.map(\.id), [pinnedID])
        XCTAssertFalse(spy.savedProfiles.contains { $0.id == newProfile.id },
                       "Profile must not be saved until user confirms")
    }

    // MARK: - Orphan detection — partial overlap

    /// Only the pinned IDs missing from the new catalog are orphaned; others are retained.
    func test_switchProfile_partialOverlap_orphansOnlyMissingIDs() {
        let keptID = UUID()
        let orphanID = UUID()
        let keptForm  = makeForm(id: keptID)
        let orphanForm = makeForm(id: orphanID)
        let (vm, _) = makeVM(pinnedIDs: [keptID, orphanID], forms: [keptForm, orphanForm])
        let belt = makeBelt(.yellow)
        let newProfile = DojangProfile(
            id: UUID(), name: "New", beltLevels: [belt],
            formIDs: [keptID], createdAt: .now, updatedAt: .now
        )

        vm.switchProfile(profile: newProfile, belt: belt)

        XCTAssertEqual(vm.pendingSchoolSwitch?.orphanedForms.count, 1)
        XCTAssertEqual(vm.pendingSchoolSwitch?.orphanedForms.first?.id, orphanID)
    }

    // MARK: - confirmSchoolSwitch

    /// Confirm drops orphaned pins, saves updated PinnedForms, applies the profile, clears pending.
    func test_confirmSchoolSwitch_dropsOrphanedPins() {
        let keptID   = UUID()
        let dropID   = UUID()
        let keptForm = makeForm(id: keptID)
        let dropForm = makeForm(id: dropID)
        let (vm, spy) = makeVM(pinnedIDs: [keptID, dropID], forms: [keptForm, dropForm])
        let belt = makeBelt(.yellow)
        let newProfile = DojangProfile(
            id: UUID(), name: "New", beltLevels: [belt],
            formIDs: [keptID], createdAt: .now, updatedAt: .now
        )

        vm.switchProfile(profile: newProfile, belt: belt)
        XCTAssertNotNil(vm.pendingSchoolSwitch)

        vm.confirmSchoolSwitch()

        XCTAssertNil(vm.pendingSchoolSwitch, "Pending must be cleared after confirm")
        XCTAssertEqual(vm.activeProfile.id, newProfile.id, "Profile must be updated")
        XCTAssertTrue(vm.pinnedForms.formIDs.contains(keptID), "Non-orphaned pin must be kept")
        XCTAssertFalse(vm.pinnedForms.formIDs.contains(dropID), "Orphaned pin must be dropped")
        XCTAssertTrue(spy.savedPinnedForms.last?.formIDs.contains(keptID) ?? false)
        XCTAssertFalse(spy.savedPinnedForms.last?.formIDs.contains(dropID) ?? true)
    }

    // MARK: - cancelSchoolSwitch

    /// Cancel clears pending state, leaves profile and pins unchanged.
    func test_cancelSchoolSwitch_leavesStateUnchanged() {
        let pinnedID = UUID()
        let pinnedForm = makeForm(id: pinnedID)
        let (vm, spy) = makeVM(pinnedIDs: [pinnedID], forms: [pinnedForm])
        let originalProfileID = vm.activeProfile.id
        let belt = makeBelt(.yellow)
        let newProfile = DojangProfile(
            id: UUID(), name: "New", beltLevels: [belt],
            formIDs: [UUID()], createdAt: .now, updatedAt: .now
        )

        vm.switchProfile(profile: newProfile, belt: belt)
        XCTAssertNotNil(vm.pendingSchoolSwitch)

        vm.cancelSchoolSwitch()

        XCTAssertNil(vm.pendingSchoolSwitch)
        XCTAssertEqual(vm.activeProfile.id, originalProfileID, "Profile must be unchanged")
        XCTAssertTrue(vm.pinnedForms.formIDs.contains(pinnedID), "Pin must be intact")
        XCTAssertFalse(spy.savedProfiles.contains { $0.id == newProfile.id },
                       "Cancelled profile must never be persisted")
    }

    // MARK: - resolvedPinnedForms

    /// resolvedPinnedForms preserves the insertion order of formIDs.
    func test_resolvedPinnedForms_preservesInsertionOrder() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID()
        let form1 = makeForm(id: id1)
        let form2 = makeForm(id: id2)
        let form3 = makeForm(id: id3)
        let (vm, _) = makeVM(pinnedIDs: [id3, id1, id2], forms: [form1, form2, form3])

        let result = vm.resolvedPinnedForms.map(\.id)
        XCTAssertEqual(result, [id3, id1, id2])
    }

    /// resolvedPinnedForms silently drops UUIDs that don't resolve in the catalog.
    func test_resolvedPinnedForms_dropsUnresolvableIDs() {
        let knownID  = UUID()
        let ghostID  = UUID()
        let knownForm = makeForm(id: knownID)
        let (vm, _) = makeVM(pinnedIDs: [knownID, ghostID], forms: [knownForm])

        let result = vm.resolvedPinnedForms
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, knownID)
    }

    // MARK: - browsableForms

    /// browsableForms includes all belt-eligible catalog forms, including already-pinned ones
    /// (the Form Browser shows them with a checkmark, not hidden).
    func test_browsableForms_includesPinnedForms() {
        let pinnedID   = UUID()
        let unpinnedID = UUID()
        let pinnedForm   = makeForm(id: pinnedID,   introducedAt: .white)
        let unpinnedForm = makeForm(id: unpinnedID, introducedAt: .white)
        let belt = makeBelt(.black)
        let profile = DojangProfile(
            id: UUID(), name: "Test", beltLevels: [belt],
            formIDs: nil, createdAt: .now, updatedAt: .now
        )
        let pinned = PinnedForms(formIDs: [pinnedID], createdAt: .now, updatedAt: .now)
        let spy = SpyUserPrefsRepository(profile: profile, beltID: belt.id, pinnedForms: pinned)
        let formRepo = StubFormRepository(forms: [pinnedForm, unpinnedForm])
        let vm = HomeViewModel(userPrefs: spy, formRepo: formRepo)

        let result = vm.browsableForms
        XCTAssertTrue(result.contains { $0.id == pinnedID },
                      "Pinned forms must appear in browser (shown with checkmark, not hidden)")
        XCTAssertTrue(result.contains { $0.id == unpinnedID })
    }

    /// browsableForms applies no family filter — all families are visible.
    func test_browsableForms_noFamilyFilter() {
        let belt = makeBelt(.black)
        let profile = DojangProfile(
            id: UUID(), name: "Test", beltLevels: [belt],
            formIDs: nil, createdAt: .now, updatedAt: .now
        )
        let spy = SpyUserPrefsRepository(profile: profile, beltID: belt.id, pinnedForms: nil)
        let forms = FormFamily.allCases.map {
            TKDForm(id: UUID(), name: "\($0)", koreanName: nil,
                    family: $0, introducedAt: .white, videos: [], notes: nil)
        }
        let formRepo = StubFormRepository(forms: forms)
        let vm = HomeViewModel(userPrefs: spy, formRepo: formRepo)

        XCTAssertEqual(vm.browsableForms.count, FormFamily.allCases.count)
    }
}

// MARK: - Test Doubles

private final class StubUserPrefsRepository: UserPrefsRepository {
    private let profile: DojangProfile
    private let beltID: UUID

    init(profile: DojangProfile, beltID: UUID) {
        self.profile = profile
        self.beltID = beltID
    }

    var activeProfile: DojangProfile? { profile }
    var trainingProfile: TrainingProfile? {
        TrainingProfile(selectedProfileID: profile.id, selectedBeltLevelID: beltID,
                        createdAt: .now, updatedAt: .now)
    }
    var sessionDefaults: SessionDefaults? {
        SessionDefaults(defaultOrder: .sequential, enabledFamilies: FormFamily.allCases,
                        createdAt: .now, updatedAt: .now)
    }
    var pinnedForms: PinnedForms? { nil }
    var onboardingState: OnboardingState? { nil }

    func save(_ trainingProfile: TrainingProfile) {}
    func save(_ sessionDefaults: SessionDefaults) {}
    func save(_ pinnedForms: PinnedForms) {}
    func save(_ onboardingState: OnboardingState) {}
    func save(_ activeProfile: DojangProfile) {}
}

private struct StubFormRepository: FormRepository {
    let forms: [TKDForm]
    var all: [TKDForm] { forms }
    func forms(for ids: Set<UUID>) -> [TKDForm] { forms.filter { ids.contains($0.id) } }
}

/// Spy variant that records every save call for assertion in school-switch tests.
private final class SpyUserPrefsRepository: UserPrefsRepository {
    private let profile: DojangProfile
    private let beltID: UUID
    private let initialPinnedForms: PinnedForms?

    private(set) var savedProfiles:    [DojangProfile]    = []
    private(set) var savedPinnedForms: [PinnedForms]      = []
    private(set) var savedTraining:    [TrainingProfile]  = []

    init(profile: DojangProfile, beltID: UUID, pinnedForms: PinnedForms?) {
        self.profile = profile
        self.beltID = beltID
        self.initialPinnedForms = pinnedForms
    }

    var activeProfile: DojangProfile? { profile }
    var trainingProfile: TrainingProfile? {
        TrainingProfile(selectedProfileID: profile.id, selectedBeltLevelID: beltID,
                        createdAt: .now, updatedAt: .now)
    }
    var sessionDefaults: SessionDefaults? {
        SessionDefaults(defaultOrder: .sequential, enabledFamilies: FormFamily.allCases,
                        createdAt: .now, updatedAt: .now)
    }
    var pinnedForms: PinnedForms? { initialPinnedForms }
    var onboardingState: OnboardingState? { nil }

    func save(_ trainingProfile: TrainingProfile) { savedTraining.append(trainingProfile) }
    func save(_ sessionDefaults: SessionDefaults) {}
    func save(_ pinnedForms: PinnedForms)         { savedPinnedForms.append(pinnedForms) }
    func save(_ onboardingState: OnboardingState) {}
    func save(_ activeProfile: DojangProfile)     { savedProfiles.append(activeProfile) }
}

// MARK: - pinForm / unpinForm / reorderPinnedForms

final class HomeViewModelPinTests: XCTestCase {

    private func makeBelt(_ canonical: CanonicalBelt = .white) -> BeltLevel {
        BeltLevel(id: UUID(), name: "\(canonical)", canonical: canonical,
                  displayOrder: 0, colorHex: "#000000", isDefault: true,
                  createdAt: .now, updatedAt: .now)
    }

    private func makeForm(id: UUID = UUID()) -> TKDForm {
        TKDForm(id: id, name: "Form", koreanName: nil,
                family: .taegeuk, introducedAt: .white, videos: [], notes: nil)
    }

    private func makeVM(
        pinnedIDs: [UUID] = [],
        forms: [TKDForm] = []
    ) -> (HomeViewModel, SpyUserPrefsRepository) {
        let belt    = makeBelt()
        let profile = DojangProfile(id: UUID(), name: "Test", beltLevels: [belt],
                                    formIDs: nil, createdAt: .now, updatedAt: .now)
        let pinned  = PinnedForms(formIDs: pinnedIDs, createdAt: .now, updatedAt: .now)
        let spy     = SpyUserPrefsRepository(profile: profile, beltID: belt.id, pinnedForms: pinned)
        let repo    = StubFormRepository(forms: forms)
        return (HomeViewModel(userPrefs: spy, formRepo: repo), spy)
    }

    // MARK: - pinForm

    func test_pinForm_addsIDToPinnedForms() {
        let id       = UUID()
        let (vm, spy) = makeVM(forms: [makeForm(id: id)])
        vm.pinForm(id)
        XCTAssertTrue(vm.pinnedForms.formIDs.contains(id))
        XCTAssertEqual(spy.savedPinnedForms.last?.formIDs.contains(id), true)
    }

    /// pinForm on an already-pinned ID must not create a duplicate.
    func test_pinForm_duplicateID_doesNotDuplicate() {
        let id       = UUID()
        let (vm, _)  = makeVM(pinnedIDs: [id], forms: [makeForm(id: id)])
        vm.pinForm(id)
        XCTAssertEqual(vm.pinnedForms.formIDs.filter { $0 == id }.count, 1)
    }

    // MARK: - unpinForm

    func test_unpinForm_removesIDFromPinnedForms() {
        let id        = UUID()
        let (vm, spy) = makeVM(pinnedIDs: [id], forms: [makeForm(id: id)])
        vm.unpinForm(id)
        XCTAssertFalse(vm.pinnedForms.formIDs.contains(id))
        XCTAssertEqual(spy.savedPinnedForms.last?.formIDs.contains(id), false)
    }

    func test_unpinForm_absentID_doesNotChangeFormIDs() {
        let existingID = UUID()
        let ghostID    = UUID()
        let (vm, _)    = makeVM(pinnedIDs: [existingID], forms: [makeForm(id: existingID)])
        vm.unpinForm(ghostID)
        XCTAssertEqual(vm.pinnedForms.formIDs, [existingID])
    }

    // MARK: - reorderPinnedForms

    /// Move item at index 0 to the end: [A, B, C] → [B, C, A].
    func test_reorderPinnedForms_movesFirstToEnd_andPersists() {
        let a = UUID(), b = UUID(), c = UUID()
        let (vm, spy) = makeVM(
            pinnedIDs: [a, b, c],
            forms: [makeForm(id: a), makeForm(id: b), makeForm(id: c)]
        )
        vm.reorderPinnedForms(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        XCTAssertEqual(vm.pinnedForms.formIDs, [b, c, a])
        XCTAssertNotNil(spy.savedPinnedForms.last)
    }
}

// MARK: - buildSession

final class HomeViewModelBuildSessionTests: XCTestCase {

    private func makeBelt(_ canonical: CanonicalBelt = .black) -> BeltLevel {
        BeltLevel(id: UUID(), name: "\(canonical)", canonical: canonical,
                  displayOrder: 0, colorHex: "#000000", isDefault: true,
                  createdAt: .now, updatedAt: .now)
    }

    private func makeForm(id: UUID = UUID(), family: FormFamily = .taegeuk,
                          introducedAt: CanonicalBelt = .white) -> TKDForm {
        TKDForm(id: id, name: "Form", koreanName: nil,
                family: family, introducedAt: introducedAt, videos: [], notes: nil)
    }

    private func makeVM(pinnedIDs: [UUID] = [], forms: [TKDForm],
                        belt: BeltLevel? = nil) -> HomeViewModel {
        let beltLevel = belt ?? makeBelt()
        let profile   = DojangProfile(id: UUID(), name: "Test", beltLevels: [beltLevel],
                                      formIDs: nil, createdAt: .now, updatedAt: .now)
        let pinned    = PinnedForms(formIDs: pinnedIDs, createdAt: .now, updatedAt: .now)
        let spy       = SpyUserPrefsRepository(profile: profile, beltID: beltLevel.id,
                                               pinnedForms: pinned)
        let repo      = StubFormRepository(forms: forms)
        return HomeViewModel(userPrefs: spy, formRepo: repo)
    }

    func test_buildSession_singleScope_returnsOneFormQueue() {
        let target = makeForm()
        let vm     = makeVM(forms: [makeForm(), target, makeForm()])
        let session = vm.buildSession(scope: .single(target.id),
                                      order: .sequential,
                                      families: FormFamily.allCases)
        XCTAssertEqual(session.queue.count, 1)
        XCTAssertEqual(session.queue.first?.id, target.id)
    }

    func test_buildSession_fullBeltScope_returnsAllEligibleForms() {
        let forms   = [makeForm(), makeForm(), makeForm()]
        let vm      = makeVM(forms: forms)
        let session = vm.buildSession(scope: .fullSet, order: .sequential,
                                      families: FormFamily.allCases)
        XCTAssertEqual(session.queue.count, forms.count)
        XCTAssertEqual(Set(session.queue.map(\.id)), Set(forms.map(\.id)))
    }

    func test_buildSession_pinnedScope_returnsOnlyPinnedForms() {
        let pinnedID   = UUID()
        let unpinnedID = UUID()
        let vm = makeVM(
            pinnedIDs: [pinnedID],
            forms: [makeForm(id: pinnedID), makeForm(id: unpinnedID)]
        )
        let session = vm.buildSession(scope: .pinned, order: .sequential,
                                      families: FormFamily.allCases)
        XCTAssertEqual(session.queue.count, 1)
        XCTAssertEqual(session.queue.first?.id, pinnedID)
    }

    func test_buildSession_randomizedOrder_containsAllFormsAndMarksOrderCorrectly() {
        let forms   = (0..<5).map { _ in makeForm() }
        let vm      = makeVM(forms: forms)
        let session = vm.buildSession(scope: .fullSet, order: .randomized,
                                      families: FormFamily.allCases)
        XCTAssertEqual(Set(session.queue.map(\.id)), Set(forms.map(\.id)))
        XCTAssertEqual(session.order, .randomized)
    }
}

// MARK: - eligibleForms

final class HomeViewModelEligibleFormsTests: XCTestCase {

    private func makeBelt(_ canonical: CanonicalBelt) -> BeltLevel {
        BeltLevel(id: UUID(), name: "\(canonical)", canonical: canonical,
                  displayOrder: 0, colorHex: "#000000", isDefault: true,
                  createdAt: .now, updatedAt: .now)
    }

    private func makeForm(id: UUID = UUID(), family: FormFamily = .taegeuk,
                          introducedAt: CanonicalBelt = .white) -> TKDForm {
        TKDForm(id: id, name: "Form", koreanName: nil,
                family: family, introducedAt: introducedAt, videos: [], notes: nil)
    }

    private func makeVM(belt: BeltLevel, forms: [TKDForm]) -> HomeViewModel {
        let profile = DojangProfile(id: UUID(), name: "Test", beltLevels: [belt],
                                    formIDs: nil, createdAt: .now, updatedAt: .now)
        let spy     = SpyUserPrefsRepository(profile: profile, beltID: belt.id, pinnedForms: nil)
        let repo    = StubFormRepository(forms: forms)
        return HomeViewModel(userPrefs: spy, formRepo: repo)
    }

    /// enabledFamilies in sessionDefaults must gate which families appear in eligibleForms.
    func test_eligibleForms_respectsEnabledFamiliesFromSessionDefaults() {
        let taegeukID = UUID()
        let palgweID  = UUID()
        let vm = makeVM(belt: makeBelt(.black), forms: [
            makeForm(id: taegeukID, family: .taegeuk),
            makeForm(id: palgweID,  family: .palgwe),
        ])

        vm.saveSessionDefaults(SessionDefaults(
            defaultOrder:    .sequential,
            enabledFamilies: [.taegeuk],
            createdAt: .now,
            updatedAt: .now
        ))

        XCTAssertEqual(vm.eligibleForms.count, 1)
        XCTAssertEqual(vm.eligibleForms.first?.id, taegeukID)
    }

    /// Forms introduced above the user's belt must not appear in eligibleForms.
    func test_eligibleForms_respectsBeltCap() {
        let belt      = makeBelt(.green)
        let whiteForm = makeForm(introducedAt: .white)
        let greenForm = makeForm(introducedAt: .green)
        let blackForm = makeForm(introducedAt: .black)  // above belt
        let vm        = makeVM(belt: belt, forms: [whiteForm, greenForm, blackForm])

        XCTAssertEqual(vm.eligibleForms.count, 2)
        XCTAssertFalse(vm.eligibleForms.contains { $0.introducedAt > .green })
    }
}
