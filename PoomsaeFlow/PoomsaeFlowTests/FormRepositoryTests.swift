import XCTest
@testable import PoomsaeFlow

final class FormRepositoryTests: XCTestCase {

    private let repo = DefaultFormRepository()

    // MARK: - all

    func test_all_returnsFullCatalog() {
        XCTAssertEqual(repo.all.count, FormsDataSource.all.count)
    }

    func test_all_isDeterministicAcrossRepeatCalls() {
        XCTAssertEqual(repo.all.map(\.id), repo.all.map(\.id))
    }

    // MARK: - forms(for:)

    func test_formsFor_emptySet_returnsEmpty() {
        XCTAssertTrue(repo.forms(for: []).isEmpty)
    }

    func test_formsFor_validIDs_returnsMatchingForms() {
        let first  = FormsDataSource.all[0]
        let second = FormsDataSource.all[1]
        let result = repo.forms(for: [first.id, second.id])
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.id == first.id })
        XCTAssertTrue(result.contains { $0.id == second.id })
    }

    func test_formsFor_mixedValidAndInvalidIDs_filtersOutUnknowns() {
        let known     = FormsDataSource.all[0]
        let unknownID = UUID()
        let result    = repo.forms(for: [known.id, unknownID])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, known.id)
    }

    func test_formsFor_allCatalogIDs_returnsFullCatalog() {
        let allIDs = Set(FormsDataSource.all.map(\.id))
        XCTAssertEqual(repo.forms(for: allIDs).count, FormsDataSource.all.count)
    }

    func test_formsFor_onlyUnknownIDs_returnsEmpty() {
        let result = repo.forms(for: [UUID(), UUID()])
        XCTAssertTrue(result.isEmpty)
    }
}
