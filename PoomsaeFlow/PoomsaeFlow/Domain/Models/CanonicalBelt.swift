/// The app-wide belt rank abstraction, independent of any dojang's specific belt system.
///
/// Dojang profiles can have many intermediate belts (e.g. Yellow Adv, Orange) that map to
/// a single CanonicalBelt via `BeltLevel.canonical`. Form eligibility is always expressed
/// in terms of CanonicalBelt so that `FormFilterService` works correctly regardless of
/// which belt system the user's dojang uses. Never use raw integers or dojang belt names
/// for eligibility comparisons.
enum CanonicalBelt: String, Codable, CaseIterable, Comparable {
    case white
    case yellow
    case yellowAdv
    case orange
    case orangeAdv
    case green
    case greenAdv
    case blue
    case blueAdv
    case red
    case redAdv
    case poom
    case black

    nonisolated var order: Int {
        switch self {
        case .white:     return 0
        case .yellow:    return 1
        case .yellowAdv: return 2
        case .orange:    return 3
        case .orangeAdv: return 4
        case .green:     return 5
        case .greenAdv:  return 6
        case .blue:      return 7
        case .blueAdv:   return 8
        case .red:       return 9
        case .redAdv:    return 10
        case .poom:      return 11
        case .black:     return 12
        }
    }

    // Explicit Comparable via order rather than relying on enum case order so that
    // the ordering is preserved even if cases are reordered during future refactors,
    // and to make the intent clear to anyone reading eligibility filter logic.
    nonisolated static func < (lhs: CanonicalBelt, rhs: CanonicalBelt) -> Bool {
        lhs.order < rhs.order
    }
}
