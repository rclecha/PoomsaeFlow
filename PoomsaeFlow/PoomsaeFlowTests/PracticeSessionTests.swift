import XCTest
@testable import PoomsaeFlow

final class PracticeSessionTests: XCTestCase {

    // MARK: - Fixtures

    private func makeForm(id: UUID = UUID()) -> TKDForm {
        TKDForm(id: id, name: "Form", koreanName: nil,
                family: .taegeuk, introducedAt: .white, videos: [], notes: nil)
    }

    private func makeSession(queue: [TKDForm], currentIndex: Int = 0) -> PracticeSession {
        PracticeSession(id: UUID(), scope: .fullSet, order: .sequential,
                        queue: queue, currentIndex: currentIndex)
    }

    // MARK: - isComplete

    func test_isComplete_atIndexZero_withNonEmptyQueue_isFalse() {
        let session = makeSession(queue: [makeForm(), makeForm()])
        XCTAssertFalse(session.isComplete)
    }

    func test_isComplete_atMidQueue_isFalse() {
        let session = makeSession(queue: [makeForm(), makeForm(), makeForm()], currentIndex: 1)
        XCTAssertFalse(session.isComplete)
    }

    func test_isComplete_atLastValidIndex_isFalse() {
        let queue = [makeForm(), makeForm()]
        let session = makeSession(queue: queue, currentIndex: queue.count - 1)
        XCTAssertFalse(session.isComplete)
    }

    func test_isComplete_whenIndexEqualsQueueCount_isTrue() {
        let queue = [makeForm(), makeForm()]
        let session = makeSession(queue: queue, currentIndex: queue.count)
        XCTAssertTrue(session.isComplete)
    }

    func test_isComplete_whenIndexExceedsQueueCount_isTrue() {
        let queue = [makeForm()]
        let session = makeSession(queue: queue, currentIndex: queue.count + 5)
        XCTAssertTrue(session.isComplete)
    }

    /// An empty queue at index 0 satisfies currentIndex >= queue.count (0 >= 0).
    func test_isComplete_emptyQueue_isTrue() {
        let session = makeSession(queue: [], currentIndex: 0)
        XCTAssertTrue(session.isComplete)
    }

    // MARK: - currentForm

    func test_currentForm_atIndexZero_returnsFirstForm() {
        let first = makeForm()
        let session = makeSession(queue: [first, makeForm()])
        XCTAssertEqual(session.currentForm?.id, first.id)
    }

    func test_currentForm_atLastValidIndex_returnsLastForm() {
        let last  = makeForm()
        let queue = [makeForm(), makeForm(), last]
        let session = makeSession(queue: queue, currentIndex: queue.count - 1)
        XCTAssertEqual(session.currentForm?.id, last.id)
    }

    func test_currentForm_emptyQueue_returnsNil() {
        let session = makeSession(queue: [])
        XCTAssertNil(session.currentForm)
    }

    func test_currentForm_negativeIndex_returnsNil() {
        let session = makeSession(queue: [makeForm()], currentIndex: -1)
        XCTAssertNil(session.currentForm)
    }

    func test_currentForm_indexAtQueueCount_returnsNil() {
        let queue   = [makeForm(), makeForm()]
        let session = makeSession(queue: queue, currentIndex: queue.count)
        XCTAssertNil(session.currentForm)
    }

    // MARK: - scope and order carry-through

    func test_scopeAndOrder_carryThroughFromInit() {
        let id   = UUID()
        let form = makeForm(id: id)
        let session = PracticeSession(id: UUID(), scope: .single(id), order: .randomized,
                                      queue: [form], currentIndex: 0)
        XCTAssertEqual(session.scope,  .single(id))
        XCTAssertEqual(session.order,  .randomized)
        XCTAssertEqual(session.queue.first?.id, id)
    }
}
