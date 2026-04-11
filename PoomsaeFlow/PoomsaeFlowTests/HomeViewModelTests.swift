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
