import Foundation

/// Protocol-driven so that:
/// 1. Tests can inject a fake catalog without touching `FormsDataSource`.
/// 2. A future migration to remote JSON only requires a new conforming type —
///    no call sites change because they depend on this protocol, not the concrete type.
protocol FormRepository {
    var all: [TKDForm] { get }
    func forms(for ids: Set<UUID>) -> [TKDForm]
}

struct DefaultFormRepository: FormRepository {
    var all: [TKDForm] {
        FormsDataSource.all
    }

    func forms(for ids: Set<UUID>) -> [TKDForm] {
        all.filter { ids.contains($0.id) }
    }
}
