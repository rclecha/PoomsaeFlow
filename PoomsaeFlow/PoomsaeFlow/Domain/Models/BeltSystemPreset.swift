import Foundation

/// A factory enum for the built-in belt configurations.
///
/// This type exists only in the data and onboarding layers. Service and presentation layers
/// must never import or reference `BeltSystemPreset` directly — they work with `DojangProfile`
/// so that user-defined custom profiles (v2) slot in without any additional changes.
/// Always call `makeProfile()` and pass the result downstream; never pass the preset itself.
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

    // MARK: - ProfileID

    /// Stable UUIDs so that a `TrainingProfile` stored in UserDefaults can always be
    /// correlated back to the correct `DojangProfile` across app launches. If these were
    /// generated with `UUID()`, every cold launch would produce a different ID and
    /// stored preferences would become orphaned.
    private enum ProfileID {
        static let worldTaekwondo = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        static let spartaTKD      = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        static let custom         = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    }

    // MARK: - BeltID

    /// Same stability requirement as ProfileID: `BeltLevel.id` is stored in
    /// `TrainingProfile.selectedBeltLevelID` and must round-trip across launches.
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

    // MARK: - makeProfile()

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
                (BeltID.spartaWhite,     "White",       .white,     0,  "#FFFFFF"),
                (BeltID.spartaYellow,    "Yellow",      .yellow,    1,  "#FFD700"),
                (BeltID.spartaYellowAdv, "Yellow Adv",  .yellowAdv, 2,  "#FFC107"),
                (BeltID.spartaOrange,    "Orange",      .orange,    3,  "#FF9800"),
                (BeltID.spartaOrangeAdv, "Orange Adv",  .orangeAdv, 4,  "#FF6F00"),
                (BeltID.spartaGreen,     "Green",       .green,     5,  "#4CAF50"),
                (BeltID.spartaGreenAdv,  "Green Adv",   .greenAdv,  6,  "#388E3C"),
                (BeltID.spartaBlue,      "Blue",        .blue,      7,  "#2196F3"),
                (BeltID.spartaBlueAdv,   "Blue Adv",    .blueAdv,   8,  "#1565C0"),
                (BeltID.spartaRed,       "Red",         .red,       9,  "#F44336"),
                (BeltID.spartaRedAdv,    "Red Adv",     .redAdv,    10, "#C62828"),
                (BeltID.spartaPoom,      "Poom",        .poom,      11, "#7B1FA2"),
                (BeltID.spartaBlack,     "Black",       .black,     12, "#212121"),
            ]
            // Explicit allow-list: every form in the global catalog that Sparta TKD teaches.
            // Keecho Sam Jang (00000001-…-0003) is intentionally excluded — Sparta TKD does
            // not test or teach it. Other schools that do teach it are unaffected because
            // this list only gates the spartaTKD profile.
            let spartaFormIDs: Set<UUID> = [
                // Keecho (Il and Ee only)
                FormsDataSource.FormID.keechoIlJang,
                FormsDataSource.FormID.keechoEeJang,
                // Taegeuk
                FormsDataSource.FormID.taegeukIlJang,
                FormsDataSource.FormID.taegeukEeJang,
                FormsDataSource.FormID.taegeukSamJang,
                FormsDataSource.FormID.taegeukSaJang,
                FormsDataSource.FormID.taegeukOhJang,
                FormsDataSource.FormID.taegeukYukJang,
                FormsDataSource.FormID.taegeukChilJang,
                FormsDataSource.FormID.taegeukPalJang,
                // Palgwe
                FormsDataSource.FormID.palgweIlJang,
                FormsDataSource.FormID.palgweEeJang,
                FormsDataSource.FormID.palgweSamJang,
                FormsDataSource.FormID.palgweSaJang,
                FormsDataSource.FormID.palgweOhJang,
                FormsDataSource.FormID.palgweYukJang,
                FormsDataSource.FormID.palgweChilJang,
                FormsDataSource.FormID.palgwePalJang,
                // Black Belt
                FormsDataSource.FormID.koryo,
                FormsDataSource.FormID.keumgang,
                FormsDataSource.FormID.taebaek,
                FormsDataSource.FormID.pyongwon,
                FormsDataSource.FormID.sipjin,
                FormsDataSource.FormID.jitae,
                FormsDataSource.FormID.cheonkwon,
                FormsDataSource.FormID.hansu,
                FormsDataSource.FormID.ilyo,
            ]
            return DojangProfile(
                id: ProfileID.spartaTKD,
                name: displayName,
                beltLevels: belts.map { id, name, canonical, order, hex in
                    BeltLevel(id: id, name: name, canonical: canonical,
                              displayOrder: order, colorHex: hex, isDefault: true,
                              createdAt: now, updatedAt: now)
                },
                formIDs: spartaFormIDs,
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
