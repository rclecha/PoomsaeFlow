import Foundation

struct PracticeSession: Identifiable {
    let id: UUID
    let scope: SessionScope
    let order: SessionOrder
    let queue: [TKDForm]
    var currentIndex: Int

    var isComplete: Bool {
        currentIndex >= queue.count
    }

    var currentForm: TKDForm? {
        guard currentIndex >= 0, currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }
}
