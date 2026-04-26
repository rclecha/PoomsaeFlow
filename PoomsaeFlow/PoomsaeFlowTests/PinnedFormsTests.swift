import XCTest
@testable import PoomsaeFlow

final class PinnedFormsTests: XCTestCase {

    // MARK: - Fixtures

    /// Fixed epoch (Jan 1 2001) so any Date() call during the test is strictly greater,
    /// making updatedAt comparisons reliable regardless of machine speed.
    private func makePins(_ ids: UUID...) -> PinnedForms {
        PinnedForms(formIDs: ids,
                    createdAt: Date(timeIntervalSinceReferenceDate: 0),
                    updatedAt: Date(timeIntervalSinceReferenceDate: 0))
    }

    // MARK: - adding(_:)

    func test_adding_newID_appendsID() {
        let initial = makePins()
        let id      = UUID()
        let result  = initial.adding(id)
        XCTAssertEqual(result.formIDs, [id])
    }

    func test_adding_newID_preservesCreatedAt() {
        let initial = makePins()
        let result  = initial.adding(UUID())
        XCTAssertEqual(result.createdAt, initial.createdAt)
    }

    func test_adding_newID_updatesUpdatedAt() {
        let initial = makePins()
        let result  = initial.adding(UUID())
        XCTAssertGreaterThan(result.updatedAt, initial.updatedAt)
    }

    func test_adding_existingID_doesNotDuplicate() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.adding(id)
        XCTAssertEqual(result.formIDs, [id])
    }

    func test_adding_existingID_doesNotChangeUpdatedAt() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.adding(id)
        XCTAssertEqual(result.updatedAt, initial.updatedAt)
    }

    // MARK: - removing(_:)

    func test_removing_existingID_removesIt() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.removing(id)
        XCTAssertTrue(result.formIDs.isEmpty)
    }

    func test_removing_existingID_updatesUpdatedAt() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.removing(id)
        XCTAssertGreaterThan(result.updatedAt, initial.updatedAt)
    }

    func test_removing_existingID_preservesCreatedAt() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.removing(id)
        XCTAssertEqual(result.createdAt, initial.createdAt)
    }

    func test_removing_absentID_doesNotChangeFormIDs() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.removing(UUID())
        XCTAssertEqual(result.formIDs, initial.formIDs)
    }

    func test_removing_absentID_doesNotChangeUpdatedAt() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.removing(UUID())
        XCTAssertEqual(result.updatedAt, initial.updatedAt)
    }

    // MARK: - reordering(fromOffsets:toOffset:)

    func test_reordering_emptyArray_remainsEmpty() {
        let initial = makePins()
        let result  = initial.reordering(fromOffsets: [], toOffset: 0)
        XCTAssertTrue(result.formIDs.isEmpty)
    }

    func test_reordering_singleItem_remainsUnchanged() {
        let id      = UUID()
        let initial = makePins(id)
        let result  = initial.reordering(fromOffsets: IndexSet(integer: 0), toOffset: 1)
        XCTAssertEqual(result.formIDs, [id])
    }

    /// Move the first item to the end: [A, B, C] → [B, C, A]
    func test_reordering_moveFirstToEnd() {
        let a = UUID(), b = UUID(), c = UUID()
        let initial = makePins(a, b, c)
        let result  = initial.reordering(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        XCTAssertEqual(result.formIDs, [b, c, a])
    }

    /// Move the last item to the start: [A, B, C] → [C, A, B]
    func test_reordering_moveLastToStart() {
        let a = UUID(), b = UUID(), c = UUID()
        let initial = makePins(a, b, c)
        let result  = initial.reordering(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        XCTAssertEqual(result.formIDs, [c, a, b])
    }

    // MARK: - removingAll(_:)

    func test_removingAll_removesMatchingIDs() {
        let a = UUID(), b = UUID(), c = UUID()
        let initial = makePins(a, b, c)
        let result  = initial.removingAll([a, c])
        XCTAssertEqual(result.formIDs, [b])
    }

    func test_removingAll_updatesUpdatedAt() {
        let a = UUID(), b = UUID()
        let initial = makePins(a, b)
        let result  = initial.removingAll([a])
        XCTAssertGreaterThan(result.updatedAt, initial.updatedAt)
    }

    func test_removingAll_preservesCreatedAt() {
        let a = UUID()
        let initial = makePins(a)
        let result  = initial.removingAll([a])
        XCTAssertEqual(result.createdAt, initial.createdAt)
    }

    func test_removingAll_emptySet_isNoOp() {
        let a = UUID()
        let initial = makePins(a)
        let result  = initial.removingAll([])
        XCTAssertEqual(result.formIDs, initial.formIDs)
        XCTAssertEqual(result.updatedAt, initial.updatedAt)
    }

    func test_removingAll_allAbsent_isNoOp() {
        let a = UUID()
        let initial = makePins(a)
        let result  = initial.removingAll([UUID(), UUID()])
        XCTAssertEqual(result.formIDs, initial.formIDs)
        XCTAssertEqual(result.updatedAt, initial.updatedAt)
    }

    func test_removingAll_allIDs_leavesEmpty() {
        let a = UUID(), b = UUID()
        let initial = makePins(a, b)
        let result  = initial.removingAll([a, b])
        XCTAssertTrue(result.formIDs.isEmpty)
    }

    // MARK: - Codable round-trip

    func test_codable_roundTrip() throws {
        let ids     = [UUID(), UUID(), UUID()]
        let original = PinnedForms(
            formIDs:   ids,
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            updatedAt: Date(timeIntervalSince1970: 2_000_000)
        )
        let data    = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PinnedForms.self, from: data)
        XCTAssertEqual(decoded.formIDs,   original.formIDs)
        XCTAssertEqual(decoded.createdAt, original.createdAt)
        XCTAssertEqual(decoded.updatedAt, original.updatedAt)
    }
}
