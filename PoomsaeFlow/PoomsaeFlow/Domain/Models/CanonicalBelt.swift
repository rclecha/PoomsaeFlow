enum CanonicalBelt: String, Codable, CaseIterable, Comparable {
    case white
    case yellow
    case green
    case blue
    case red
    case poom
    case black

    var order: Int {
        switch self {
        case .white:  return 0
        case .yellow: return 1
        case .green:  return 2
        case .blue:   return 3
        case .red:    return 4
        case .poom:   return 5
        case .black:  return 6
        }
    }

    static func < (lhs: CanonicalBelt, rhs: CanonicalBelt) -> Bool {
        lhs.order < rhs.order
    }
}
