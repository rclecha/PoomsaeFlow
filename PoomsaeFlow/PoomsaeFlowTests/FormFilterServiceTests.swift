import XCTest
@testable import PoomsaeFlow

final class FormFilterServiceTests: XCTestCase {

    // MARK: - Fixtures

    private func makeBeltLevel(canonical: CanonicalBelt, displayOrder: Int = 0) -> BeltLevel {
        BeltLevel(id: UUID(), name: "\(canonical)", canonical: canonical,
                  displayOrder: displayOrder, colorHex: "#000000", isDefault: true,
                  createdAt: .now, updatedAt: .now)
    }

    private func makeProfile(formIDs: Set<UUID>? = nil) -> DojangProfile {
        DojangProfile(id: UUID(), name: "Test Profile", beltLevels: [],
                      formIDs: formIDs, createdAt: .now, updatedAt: .now)
    }

    private func makeForm(id: UUID = UUID(), family: FormFamily,
                          introducedAt: CanonicalBelt) -> TKDForm {
        TKDForm(id: id, name: "Form \(id.uuidString.prefix(4))", koreanName: nil,
                family: family, introducedAt: introducedAt, videos: [], notes: nil)
    }

    // MARK: - Belt eligibility

    /// Yellow canonical sees white and yellow forms but nothing introduced at green or above.
    func test_yellowBelt_seesWhiteAndYellowForms_notGreenOrAbove() {
        let belt = makeBeltLevel(canonical: .yellow)
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .white),
            makeForm(family: .taegeuk, introducedAt: .yellow),
            makeForm(family: .taegeuk, introducedAt: .green),
            makeForm(family: .taegeuk, introducedAt: .blue),
        ]

        let result = FormFilterService.eligibleForms(
            userBelt: belt, profile: makeProfile(),
            allForms: forms, enabledFamilies: [.taegeuk]
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.introducedAt <= .yellow })
    }

    /// Sparta "Orange Adv" maps to canonical .orangeAdv — it must see forms introduced up to
    /// and including .orangeAdv, but nothing at .green or above, proving eligibility goes
    /// through canonical order, not display name.
    func test_spartaOrangeAdv_seesFormsUpToOrangeAdv_notGreenOrAbove() {
        let spartaOrangeAdv = BeltLevel(id: UUID(), name: "Orange Adv", canonical: .orangeAdv,
                                        displayOrder: 4, colorHex: "#FF6F00", isDefault: true,
                                        createdAt: .now, updatedAt: .now)
        let profile = makeProfile()
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .white),
            makeForm(family: .taegeuk, introducedAt: .yellow),
            makeForm(family: .taegeuk, introducedAt: .yellowAdv),
            makeForm(family: .taegeuk, introducedAt: .orange),
            makeForm(family: .taegeuk, introducedAt: .orangeAdv),
            makeForm(family: .taegeuk, introducedAt: .green),    // above — must be excluded
            makeForm(family: .taegeuk, introducedAt: .blue),     // above — must be excluded
        ]

        let result = FormFilterService.eligibleForms(
            userBelt: spartaOrangeAdv, profile: profile,
            allForms: forms, enabledFamilies: [.taegeuk]
        )

        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result.allSatisfy { $0.introducedAt <= .orangeAdv })
        XCTAssertFalse(result.contains { $0.introducedAt == .green })
        XCTAssertFalse(result.contains { $0.introducedAt == .blue })
    }

    // MARK: - Family filtering

    /// Disabling a family must exclude all its forms even when the belt is eligible for them.
    func test_disabledFamily_isExcludedFromResults() {
        let belt = makeBeltLevel(canonical: .red)
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .yellow),
            makeForm(family: .palgwe,  introducedAt: .yellow),  // disabled
            makeForm(family: .keecho,  introducedAt: .white),
        ]

        let result = FormFilterService.eligibleForms(
            userBelt: belt, profile: makeProfile(),
            allForms: forms, enabledFamilies: [.taegeuk, .keecho]
        )

        XCTAssertFalse(result.contains { $0.family == .palgwe })
        XCTAssertTrue(result.contains  { $0.family == .taegeuk })
        XCTAssertTrue(result.contains  { $0.family == .keecho })
    }

    /// With all families enabled and a black belt, every form in the catalog is returned.
    func test_allFamiliesEnabled_returnsAllEligibleForms() {
        let belt = makeBeltLevel(canonical: .black)
        let forms = FormFamily.allCases.map { makeForm(family: $0, introducedAt: .white) }

        let result = FormFilterService.eligibleForms(
            userBelt: belt, profile: makeProfile(),
            allForms: forms, enabledFamilies: FormFamily.allCases
        )

        XCTAssertEqual(result.count, FormFamily.allCases.count)
    }

    // MARK: - Profile formIDs gating

    /// A profile with an explicit formIDs set limits results to only those IDs,
    /// regardless of belt rank — the profile's catalog is the outer boundary.
    func test_profileWithExplicitFormIDs_onlyReturnsThoseForms() {
        let belt = makeBeltLevel(canonical: .black)
        let allowedID = UUID()
        let blockedID = UUID()
        let forms = [
            makeForm(id: allowedID, family: .taegeuk, introducedAt: .white),
            makeForm(id: blockedID, family: .taegeuk, introducedAt: .white),
        ]

        let result = FormFilterService.eligibleForms(
            userBelt: belt, profile: makeProfile(formIDs: [allowedID]),
            allForms: forms, enabledFamilies: [.taegeuk]
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, allowedID)
    }

    /// A profile with formIDs = nil imposes no catalog filter — all belt-eligible forms appear.
    func test_profileWithNilFormIDs_returnsAllBeltEligibleForms() {
        let belt = makeBeltLevel(canonical: .yellow)
        let forms = [
            makeForm(family: .taegeuk, introducedAt: .white),
            makeForm(family: .taegeuk, introducedAt: .yellow),
            makeForm(family: .taegeuk, introducedAt: .green),  // above belt — excluded
        ]

        let result = FormFilterService.eligibleForms(
            userBelt: belt, profile: makeProfile(formIDs: nil),
            allForms: forms, enabledFamilies: [.taegeuk]
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.introducedAt <= .yellow })
    }
}
