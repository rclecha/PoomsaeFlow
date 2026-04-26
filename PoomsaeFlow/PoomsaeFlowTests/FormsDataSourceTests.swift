import XCTest
@testable import PoomsaeFlow

final class FormsDataSourceTests: XCTestCase {

    private let all = FormsDataSource.all

    // MARK: - Total count

    /// Verified against source: 3 Keecho + 8 Taegeuk + 8 Palgwe + 1 Poom + 9 Black Belt = 29.
    func test_totalCount_is29() {
        XCTAssertEqual(all.count, 29)
    }

    // MARK: - Per-family distribution

    func test_familyDistribution() {
        let count: (FormFamily) -> Int = { family in self.all.filter { $0.family == family }.count }
        XCTAssertEqual(count(.keecho),    3)
        XCTAssertEqual(count(.taegeuk),   8)
        XCTAssertEqual(count(.palgwe),    8)
        XCTAssertEqual(count(.poom),      1)
        XCTAssertEqual(count(.blackBelt), 9)
    }

    // MARK: - UUID uniqueness

    func test_allUUIDsAreUnique() {
        let ids = all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate UUIDs detected in catalog")
    }

    // MARK: - Field completeness

    func test_allFormsHaveNonEmptyName() {
        XCTAssertTrue(all.allSatisfy { !$0.name.isEmpty })
    }

    func test_allFormsHaveNonNilKoreanName() {
        let missing = all.filter { $0.koreanName == nil }.map(\.name)
        XCTAssertTrue(missing.isEmpty, "Forms missing Korean name: \(missing)")
    }

    /// introducedAt is a non-optional CanonicalBelt — this asserts every value is a
    /// recognized case so stale raw values (from a rename) would surface here.
    func test_allFormsHaveRecognizedIntroducedAt() {
        XCTAssertTrue(all.allSatisfy { CanonicalBelt.allCases.contains($0.introducedAt) })
    }

    /// Keecho Sam Jang and Hwarang intentionally ship with no videos.
    /// All other 27 forms must have at least one video resource.
    func test_catalogVideoCompleteness_twoKnownExceptions() {
        let noVideos = all.filter { $0.videos.isEmpty }.map(\.name)
        XCTAssertEqual(
            noVideos.sorted(),
            ["Hwarang", "Keecho Sam Jang"].sorted(),
            "Unexpected change in forms that have no videos: \(noVideos)"
        )
    }
}
