import XCTest
@testable import PoomsaeFlow

final class FormFamilyTests: XCTestCase {

    // MARK: - allCases

    func test_allCases_hasFiveMembers() {
        XCTAssertEqual(FormFamily.allCases.count, 5)
    }

    // MARK: - displayName

    func test_displayName_keecho() {
        XCTAssertEqual(FormFamily.keecho.displayName, "Keecho")
    }

    func test_displayName_taegeuk() {
        XCTAssertEqual(FormFamily.taegeuk.displayName, "Taegeuk")
    }

    func test_displayName_palgwe() {
        XCTAssertEqual(FormFamily.palgwe.displayName, "Palgwe")
    }

    func test_displayName_poom() {
        XCTAssertEqual(FormFamily.poom.displayName, "Poom")
    }

    func test_displayName_blackBelt() {
        XCTAssertEqual(FormFamily.blackBelt.displayName, "Black Belt")
    }

    // MARK: - Codable round-trips

    func test_codable_roundTripAllCases() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for family in FormFamily.allCases {
            let data    = try encoder.encode(family)
            let decoded = try decoder.decode(FormFamily.self, from: data)
            XCTAssertEqual(decoded, family, "Round-trip failed for \(family)")
        }
    }
}
