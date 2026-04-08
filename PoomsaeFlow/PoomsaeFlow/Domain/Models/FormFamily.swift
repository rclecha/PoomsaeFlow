enum FormFamily: String, Codable, CaseIterable {
    case keecho
    case taegeuk
    case palgwe
    case poom
    case blackBelt

    var displayName: String {
        switch self {
        case .keecho:   return "Keecho"
        case .taegeuk:  return "Taegeuk"
        case .palgwe:   return "Palgwe"
        case .poom:     return "Poom"
        case .blackBelt: return "Black Belt"
        }
    }
}
