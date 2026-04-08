import XCTest
@testable import PoomsaeFlow

final class SessionBuilderTests: XCTestCase {

    // MARK: - Fixtures

    private func makeForm(id: UUID = UUID()) -> TKDForm {
        TKDForm(id: id, name: "Form \(id.uuidString.prefix(4))", koreanName: nil,
                family: .taegeuk, introducedAt: .white, videos: [], notes: nil)
    }

    private func build(scope: SessionScope, order: SessionOrder,
                       forms: [TKDForm], pinnedIDs: [UUID] = []) -> PracticeSession {
        SessionBuilder.buildSession(scope: scope, order: order,
                                    eligibleForms: forms, pinnedIDs: pinnedIDs)
    }

    // MARK: - Order

    /// Sequential must not reorder the input — the caller controls canonical ordering.
    func test_sequentialOrder_preservesInputOrder() {
        let forms = [makeForm(), makeForm(), makeForm()]
        let session = build(scope: .fullSet, order: .sequential, forms: forms)
        XCTAssertEqual(session.queue.map(\.id), forms.map(\.id))
    }

    /// Randomized must contain all the same forms (no drops, no duplicates) and must
    /// produce a different ordering at least once across 20 attempts. With 10 items the
    /// probability that all 20 shuffles match the original is (1/10!)^20 ≈ 10^-130.
    func test_randomizedOrder_containsAllFormsInDifferentOrder() {
        let forms = (0..<10).map { _ in makeForm() }
        let originalIDs = forms.map(\.id)

        var sawDifferentOrder = false
        for _ in 0..<20 {
            let session = build(scope: .fullSet, order: .randomized, forms: forms)
            XCTAssertEqual(Set(session.queue.map(\.id)), Set(originalIDs),
                           "Randomized queue must contain exactly the same forms")
            if session.queue.map(\.id) != originalIDs {
                sawDifferentOrder = true
                break
            }
        }
        XCTAssertTrue(sawDifferentOrder,
                      "Randomized order should differ from input order across 20 attempts")
    }

    // MARK: - Scope resolution

    /// single(uuid) must produce a one-form queue for exactly the requested form.
    func test_singleScope_producesExactlyOneForm() {
        let target = makeForm()
        let forms = [makeForm(), target, makeForm()]
        let session = build(scope: .single(target.id), order: .sequential, forms: forms)
        XCTAssertEqual(session.queue.count, 1)
        XCTAssertEqual(session.queue.first?.id, target.id)
    }

    /// fullSet passes through the entire eligible list — scope performs no additional filtering.
    func test_fullSetScope_includesAllEligibleForms() {
        let forms = [makeForm(), makeForm(), makeForm()]
        let session = build(scope: .fullSet, order: .sequential, forms: forms)
        XCTAssertEqual(session.queue.count, forms.count)
        XCTAssertEqual(session.queue.map(\.id), forms.map(\.id))
    }

    /// custom([uuid]) returns only the specified forms in the order they appear
    /// among the eligible forms (not the order of the UUID list).
    func test_customScope_returnsOnlySpecifiedForms() {
        let a = makeForm()
        let b = makeForm()
        let c = makeForm()
        let session = build(scope: .custom([a.id, c.id]), order: .sequential, forms: [a, b, c])
        XCTAssertEqual(session.queue.count, 2)
        XCTAssertTrue(session.queue.contains  { $0.id == a.id })
        XCTAssertFalse(session.queue.contains { $0.id == b.id })
        XCTAssertTrue(session.queue.contains  { $0.id == c.id })
    }

    /// pinned uses pinnedIDs to filter eligibleForms — forms not in pinnedIDs are excluded.
    func test_pinnedScope_returnsOnlyPinnedForms() {
        let pinned1 = makeForm()
        let pinned2 = makeForm()
        let notPinned = makeForm()
        let session = build(scope: .pinned, order: .sequential,
                            forms: [pinned1, pinned2, notPinned],
                            pinnedIDs: [pinned1.id, pinned2.id])
        XCTAssertEqual(session.queue.count, 2)
        XCTAssertTrue(session.queue.contains  { $0.id == pinned1.id })
        XCTAssertTrue(session.queue.contains  { $0.id == pinned2.id })
        XCTAssertFalse(session.queue.contains { $0.id == notPinned.id })
    }

    // MARK: - Initial state

    /// Every freshly built session starts at index 0 regardless of scope or order.
    func test_builtSession_alwaysStartsAtIndexZero() {
        let forms = [makeForm(), makeForm()]
        let sequential  = build(scope: .fullSet, order: .sequential,  forms: forms)
        let randomized  = build(scope: .fullSet, order: .randomized,  forms: forms)
        XCTAssertEqual(sequential.currentIndex, 0)
        XCTAssertEqual(randomized.currentIndex, 0)
    }
}
