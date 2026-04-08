import Foundation

enum BeltSystemPreset: String, Codable, CaseIterable {
    case worldTaekwondo
    case spartaTKD
    case custom

    var displayName: String {
        switch self {
        case .worldTaekwondo: return "World Taekwondo"
        case .spartaTKD:      return "Sparta TKD"
        case .custom:         return "Custom"
        }
    }

    private enum ProfileID {
        static let worldTaekwondo = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        static let spartaTKD      = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        static let custom         = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    }

    private enum BeltID {
        // World Taekwondo
        static let wtWhite  = UUID(uuidString: "11000000-0000-0000-0000-000000000001")!
        static let wtYellow = UUID(uuidString: "11000000-0000-0000-0000-000000000002")!
        static let wtGreen  = UUID(uuidString: "11000000-0000-0000-0000-000000000003")!
        static let wtBlue   = UUID(uuidString: "11000000-0000-0000-0000-000000000004")!
        static let wtRed    = UUID(uuidString: "11000000-0000-0000-0000-000000000005")!
        static let wtBlack  = UUID(uuidString: "11000000-0000-0000-0000-000000000006")!
        // Sparta TKD
        static let spartaWhite     = UUID(uuidString: "12000000-0000-0000-0000-000000000001")!
        static let spartaYellow    = UUID(uuidString: "12000000-0000-0000-0000-000000000002")!
        static let spartaYellowAdv = UUID(uuidString: "12000000-0000-0000-0000-000000000003")!
        static let spartaOrange    = UUID(uuidString: "12000000-0000-0000-0000-000000000004")!
        static let spartaOrangeAdv = UUID(uuidString: "12000000-0000-0000-0000-000000000005")!
        static let spartaGreen     = UUID(uuidString: "12000000-0000-0000-0000-000000000006")!
        static let spartaGreenAdv  = UUID(uuidString: "12000000-0000-0000-0000-000000000007")!
        static let spartaBlue      = UUID(uuidString: "12000000-0000-0000-0000-000000000008")!
        static let spartaBlueAdv   = UUID(uuidString: "12000000-0000-0000-0000-000000000009")!
        static let spartaRed       = UUID(uuidString: "12000000-0000-0000-0000-000000000010")!
        static let spartaRedAdv    = UUID(uuidString: "12000000-0000-0000-0000-000000000011")!
        static let spartaPoom      = UUID(uuidString: "12000000-0000-0000-0000-000000000012")!
        static let spartaBlack     = UUID(uuidString: "12000000-0000-0000-0000-000000000013")!
    }

    func makeProfile() -> DojangProfile {
        let now = Date()
        switch self {
        case .worldTaekwondo:
            let belts: [(UUID, String, CanonicalBelt, Int, String)] = [
                (BeltID.wtWhite,  "White",  .white,  0, "#FFFFFF"),
                (BeltID.wtYellow, "Yellow", .yellow, 1, "#FFD700"),
                (BeltID.wtGreen,  "Green",  .green,  2, "#4CAF50"),
                (BeltID.wtBlue,   "Blue",   .blue,   3, "#2196F3"),
                (BeltID.wtRed,    "Red",    .red,    4, "#F44336"),
                (BeltID.wtBlack,  "Black",  .black,  5, "#212121"),
            ]
            return DojangProfile(
                id: ProfileID.worldTaekwondo,
                name: displayName,
                beltLevels: belts.map { id, name, canonical, order, hex in
                    BeltLevel(id: id, name: name, canonical: canonical,
                              displayOrder: order, colorHex: hex, isDefault: true,
                              createdAt: now, updatedAt: now)
                },
                formIDs: nil,
                createdAt: now,
                updatedAt: now
            )

        case .spartaTKD:
            let belts: [(UUID, String, CanonicalBelt, Int, String)] = [
                (BeltID.spartaWhite,     "White",       .white,  0,  "#FFFFFF"),
                (BeltID.spartaYellow,    "Yellow",      .yellow, 1,  "#FFD700"),
                (BeltID.spartaYellowAdv, "Yellow Adv",  .yellow, 2,  "#FFC107"),
                (BeltID.spartaOrange,    "Orange",      .yellow, 3,  "#FF9800"),
                (BeltID.spartaOrangeAdv, "Orange Adv",  .yellow, 4,  "#FF6F00"),
                (BeltID.spartaGreen,     "Green",       .green,  5,  "#4CAF50"),
                (BeltID.spartaGreenAdv,  "Green Adv",   .green,  6,  "#388E3C"),
                (BeltID.spartaBlue,      "Blue",        .blue,   7,  "#2196F3"),
                (BeltID.spartaBlueAdv,   "Blue Adv",    .blue,   8,  "#1565C0"),
                (BeltID.spartaRed,       "Red",         .red,    9,  "#F44336"),
                (BeltID.spartaRedAdv,    "Red Adv",     .red,    10, "#C62828"),
                (BeltID.spartaPoom,      "Poom",        .poom,   11, "#7B1FA2"),
                (BeltID.spartaBlack,     "Black",       .black,  12, "#212121"),
            ]
            return DojangProfile(
                id: ProfileID.spartaTKD,
                name: displayName,
                beltLevels: belts.map { id, name, canonical, order, hex in
                    BeltLevel(id: id, name: name, canonical: canonical,
                              displayOrder: order, colorHex: hex, isDefault: true,
                              createdAt: now, updatedAt: now)
                },
                formIDs: nil,
                createdAt: now,
                updatedAt: now
            )

        case .custom:
            // v2 — shows "coming soon" in UI; returns empty profile
            return DojangProfile(
                id: ProfileID.custom,
                name: displayName,
                beltLevels: [],
                formIDs: nil,
                createdAt: now,
                updatedAt: now
            )
        }
    }
}
