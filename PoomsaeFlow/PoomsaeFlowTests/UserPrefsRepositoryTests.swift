import XCTest
@testable import PoomsaeFlow

final class DefaultUserPrefsRepositoryTests: XCTestCase {

    // A dedicated suite keeps these tests isolated from UserDefaults.standard.
    private let suiteName = "test.DefaultUserPrefsRepository"
    private var sut: DefaultUserPrefsRepository!

    override func setUp() {
        super.setUp()
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
        sut = DefaultUserPrefsRepository(defaults: testDefaults)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        sut = nil
        super.tearDown()
    }

    // MARK: - Nil before first save

    func test_trainingProfile_nilBeforeFirstSave() {
        XCTAssertNil(sut.trainingProfile)
    }

    func test_sessionDefaults_nilBeforeFirstSave() {
        XCTAssertNil(sut.sessionDefaults)
    }

    func test_pinnedForms_nilBeforeFirstSave() {
        XCTAssertNil(sut.pinnedForms)
    }

    func test_onboardingState_nilBeforeFirstSave() {
        XCTAssertNil(sut.onboardingState)
    }

    func test_activeProfile_nilBeforeFirstSave() {
        XCTAssertNil(sut.activeProfile)
    }

    // MARK: - Round-trips

    func test_trainingProfile_roundTrip() {
        let original = TrainingProfile(
            selectedProfileID:   UUID(),
            selectedBeltLevelID: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        sut.save(original)
        let result = sut.trainingProfile
        XCTAssertEqual(result?.selectedProfileID,    original.selectedProfileID)
        XCTAssertEqual(result?.selectedBeltLevelID,  original.selectedBeltLevelID)
        XCTAssertEqual(result?.createdAt,            original.createdAt)
        XCTAssertEqual(result?.updatedAt,            original.updatedAt)
    }

    func test_sessionDefaults_roundTrip() {
        let original = SessionDefaults(
            defaultOrder:    .randomized,
            enabledFamilies: [.taegeuk, .palgwe],
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        sut.save(original)
        let result = sut.sessionDefaults
        XCTAssertEqual(result?.defaultOrder,    original.defaultOrder)
        XCTAssertEqual(result?.enabledFamilies, original.enabledFamilies)
        XCTAssertEqual(result?.createdAt,       original.createdAt)
        XCTAssertEqual(result?.updatedAt,       original.updatedAt)
    }

    func test_pinnedForms_roundTrip() {
        let ids      = [UUID(), UUID(), UUID()]
        let original = PinnedForms(
            formIDs:   ids,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        sut.save(original)
        let result = sut.pinnedForms
        XCTAssertEqual(result?.formIDs,   original.formIDs)
        XCTAssertEqual(result?.createdAt, original.createdAt)
        XCTAssertEqual(result?.updatedAt, original.updatedAt)
    }

    func test_onboardingState_roundTrip() {
        let original = OnboardingState(
            isOnboarded:    true,
            hasSeenPinHint: false,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        sut.save(original)
        let result = sut.onboardingState
        XCTAssertEqual(result?.isOnboarded,    original.isOnboarded)
        XCTAssertEqual(result?.hasSeenPinHint, original.hasSeenPinHint)
        XCTAssertEqual(result?.createdAt,      original.createdAt)
        XCTAssertEqual(result?.updatedAt,      original.updatedAt)
    }

    func test_activeProfile_roundTrip() {
        let beltID = UUID()
        let belt   = BeltLevel(
            id: beltID, name: "White", canonical: .white,
            displayOrder: 0, colorHex: "#FFFFFF", isDefault: true,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        let original = DojangProfile(
            id: UUID(), name: "Test Dojang",
            beltLevels: [belt],
            formIDs: nil,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        sut.save(original)
        let result = sut.activeProfile
        XCTAssertEqual(result?.id,   original.id)
        XCTAssertEqual(result?.name, original.name)
        XCTAssertEqual(result?.beltLevels.count, 1)
        XCTAssertEqual(result?.beltLevels.first?.id, beltID)
        XCTAssertNil(result?.formIDs,
                     "nil formIDs (unrestricted catalog) must survive the round-trip")
    }

    // MARK: - Overwrite

    func test_savingNewValue_replacesOldValue() {
        let first  = PinnedForms(formIDs: [UUID()],         createdAt: .now, updatedAt: .now)
        let second = PinnedForms(formIDs: [UUID(), UUID()], createdAt: .now, updatedAt: .now)
        sut.save(first)
        sut.save(second)
        XCTAssertEqual(sut.pinnedForms?.formIDs.count, 2)
    }

    // MARK: - Corrupted data returns nil

    /// Writing non-JSON bytes to the storage key must return nil rather than crashing.
    func test_corruptedData_returnsNilForTrainingProfile() throws {
        let garbage = try XCTUnwrap("not-valid-json".data(using: .utf8))
        UserDefaults(suiteName: suiteName)?
            .set(garbage, forKey: "com.ryan.PoomsaeFlow.trainingProfile")
        XCTAssertNil(sut.trainingProfile)
    }

    func test_corruptedData_returnsNilForPinnedForms() throws {
        let garbage = try XCTUnwrap("not-valid-json".data(using: .utf8))
        UserDefaults(suiteName: suiteName)?
            .set(garbage, forKey: "com.ryan.PoomsaeFlow.pinnedForms")
        XCTAssertNil(sut.pinnedForms)
    }
}
