import Foundation

/// The compile-time form catalog. All UUIDs are hardcoded literals — never generated with
/// `UUID()` — because `FormAttempt` records stored in SwiftData reference these IDs forever.
/// Changing a UUID here would silently orphan every historical attempt for that form.
///
/// The catalog is a static array rather than a database table because its contents never
/// change at runtime. Keeping it here means the repository layer can swap in a remote JSON
/// source in v2 without touching any call sites: `FormsRepository` already abstracts access,
/// and this file becomes a single-file migration target.
enum FormsDataSource {
    static let all: [TKDForm] = keecho + taegeuk + palgwe + poom + blackBelt

    // MARK: - VideoSource

    /// Named constants for video attribution strings. A typo in a source name would
    /// silently produce wrong attribution in the UI across every affected form.
    private enum VideoSource {
        static let spartaTKD = "Sparta TKD"
        static let kukkiwon  = "Kukkiwon"
    }

    // MARK: - youtube(_:)

    /// Constructs a YouTube watch URL from a bare video ID. Keeps each form entry to
    /// a single short identifier rather than repeating the full URL prefix 22 times.
    private static func youtube(_ videoID: String) -> URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
    }

    // MARK: - FormID

    /// Single source of truth for all form UUIDs. Grouped here — not scattered through
    /// the form definitions below — so that adding, renaming, or auditing an ID requires
    /// touching exactly one place in this file.
    private enum FormID {
        // Keecho
        static let keechoIlJang  = UUID(uuidString: "00000001-0000-0000-0000-000000000001")!
        static let keechoEeJang  = UUID(uuidString: "00000001-0000-0000-0000-000000000002")!
        static let keechoSamJang = UUID(uuidString: "00000001-0000-0000-0000-000000000003")!
        // Taegeuk
        static let taegeukIlJang   = UUID(uuidString: "00000002-0000-0000-0000-000000000001")!
        static let taegeukEeJang   = UUID(uuidString: "00000002-0000-0000-0000-000000000002")!
        static let taegeukSamJang  = UUID(uuidString: "00000002-0000-0000-0000-000000000003")!
        static let taegeukSaJang   = UUID(uuidString: "00000002-0000-0000-0000-000000000004")!
        static let taegeukOhJang   = UUID(uuidString: "00000002-0000-0000-0000-000000000005")!
        static let taegeukYukJang  = UUID(uuidString: "00000002-0000-0000-0000-000000000006")!
        static let taegeukChilJang = UUID(uuidString: "00000002-0000-0000-0000-000000000007")!
        static let taegeukPalJang  = UUID(uuidString: "00000002-0000-0000-0000-000000000008")!
        // Palgwe
        static let palgweIlJang   = UUID(uuidString: "00000003-0000-0000-0000-000000000001")!
        static let palgweEeJang   = UUID(uuidString: "00000003-0000-0000-0000-000000000002")!
        static let palgweSamJang  = UUID(uuidString: "00000003-0000-0000-0000-000000000003")!
        static let palgweSaJang   = UUID(uuidString: "00000003-0000-0000-0000-000000000004")!
        static let palgweOhJang   = UUID(uuidString: "00000003-0000-0000-0000-000000000005")!
        static let palgweYukJang  = UUID(uuidString: "00000003-0000-0000-0000-000000000006")!
        static let palgweChilJang = UUID(uuidString: "00000003-0000-0000-0000-000000000007")!
        static let palgwePalJang  = UUID(uuidString: "00000003-0000-0000-0000-000000000008")!
        // Poom
        static let hwarang = UUID(uuidString: "00000004-0000-0000-0000-000000000001")!
        // Black Belt
        static let koryo      = UUID(uuidString: "00000005-0000-0000-0000-000000000001")!
        static let keumgang   = UUID(uuidString: "00000005-0000-0000-0000-000000000002")!
        static let taebaek    = UUID(uuidString: "00000005-0000-0000-0000-000000000003")!
        static let pyongwon   = UUID(uuidString: "00000005-0000-0000-0000-000000000004")!
        static let sipjin     = UUID(uuidString: "00000005-0000-0000-0000-000000000005")!
        static let jitae      = UUID(uuidString: "00000005-0000-0000-0000-000000000006")!
        static let cheonkwon  = UUID(uuidString: "00000005-0000-0000-0000-000000000007")!
        static let hansu      = UUID(uuidString: "00000005-0000-0000-0000-000000000008")!
        static let ilyo       = UUID(uuidString: "00000005-0000-0000-0000-000000000009")!
    }

    // MARK: - Keecho

    private static let keecho: [TKDForm] = [
        TKDForm(
            id: FormID.keechoIlJang,
            name: "Keecho Il Jang",
            koreanName: "기초 일장",
            family: .keecho,
            introducedAt: .white,
            videos: [
                VideoResource(
                    url: youtube("FD9m2KE-9D4"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.keechoEeJang,
            name: "Keecho Ee Jang",
            koreanName: "기초 이장",
            family: .keecho,
            introducedAt: .white,
            videos: [
                VideoResource(
                    url: youtube("gfftpjOn5fY"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.keechoSamJang,
            name: "Keecho Sam Jang",
            koreanName: "기초 삼장",
            family: .keecho,
            introducedAt: .white,
            videos: [],
            notes: nil
        ),
    ]

    // MARK: - Taegeuk

    private static let taegeuk: [TKDForm] = [
        TKDForm(
            id: FormID.taegeukIlJang,
            name: "Taegeuk Il Jang",
            koreanName: "태극 일장",
            family: .taegeuk,
            introducedAt: .yellow,
            videos: [
                VideoResource(
                    url: youtube("iCmGecTpzE4"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukEeJang,
            name: "Taegeuk Ee Jang",
            koreanName: "태극 이장",
            family: .taegeuk,
            introducedAt: .orange,
            videos: [
                VideoResource(
                    url: youtube("YB2-yomN1pw"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukSamJang,
            name: "Taegeuk Sam Jang",
            koreanName: "태극 삼장",
            family: .taegeuk,
            introducedAt: .green,
            videos: [
                VideoResource(
                    url: youtube("7iREIx5oC4c"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukSaJang,
            name: "Taegeuk Sa Jang",
            koreanName: "태극 사장",
            family: .taegeuk,
            introducedAt: .greenAdv,
            videos: [
                VideoResource(
                    url: youtube("bhLQfcXy__Q"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukOhJang,
            name: "Taegeuk Oh Jang",
            koreanName: "태극 오장",
            family: .taegeuk,
            introducedAt: .blue,
            videos: [
                VideoResource(
                    url: youtube("cRgGd5_mDd8"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukYukJang,
            name: "Taegeuk Yuk Jang",
            koreanName: "태극 육장",
            family: .taegeuk,
            introducedAt: .blueAdv,
            videos: [
                VideoResource(
                    url: youtube("UCxVGTbAENU"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukChilJang,
            name: "Taegeuk Chil Jang",
            koreanName: "태극 칠장",
            family: .taegeuk,
            introducedAt: .red,
            videos: [
                VideoResource(
                    url: youtube("WjpsIeeGlSA"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taegeukPalJang,
            name: "Taegeuk Pal Jang",
            koreanName: "태극 팔장",
            family: .taegeuk,
            introducedAt: .redAdv,
            videos: [
                VideoResource(
                    url: youtube("4IL0hqcs_jE"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
    ]

    // MARK: - Palgwe

    private static let palgwe: [TKDForm] = [
        TKDForm(
            id: FormID.palgweIlJang,
            name: "Palgwe Il Jang",
            koreanName: "팔괘 일장",
            family: .palgwe,
            introducedAt: .yellowAdv,
            videos: [
                VideoResource(
                    url: youtube("uiLBDwJdQUU"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgweEeJang,
            name: "Palgwe Ee Jang",
            koreanName: "팔괘 이장",
            family: .palgwe,
            introducedAt: .orangeAdv,
            videos: [
                VideoResource(
                    url: youtube("3jbKCbI-rJA"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgweSamJang,
            name: "Palgwe Sam Jang",
            koreanName: "팔괘 삼장",
            family: .palgwe,
            introducedAt: .green,
            videos: [
                VideoResource(
                    url: youtube("XJVOHDJLaw0"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgweSaJang,
            name: "Palgwe Sa Jang",
            koreanName: "팔괘 사장",
            family: .palgwe,
            introducedAt: .greenAdv,
            videos: [
                VideoResource(
                    url: youtube("rtZGG5-P0Wo"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgweOhJang,
            name: "Palgwe Oh Jang",
            koreanName: "팔괘 오장",
            family: .palgwe,
            introducedAt: .blue,
            videos: [
                VideoResource(
                    url: youtube("grRm0Q8rpx8"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgweYukJang,
            name: "Palgwe Yuk Jang",
            koreanName: "팔괘 육장",
            family: .palgwe,
            introducedAt: .blueAdv,
            videos: [
                VideoResource(
                    url: youtube("veARrGqOxpM"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgweChilJang,
            name: "Palgwe Chil Jang",
            koreanName: "팔괘 칠장",
            family: .palgwe,
            introducedAt: .red,
            videos: [
                VideoResource(
                    url: youtube("vIcnLp4hPw8"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.palgwePalJang,
            name: "Palgwe Pal Jang",
            koreanName: "팔괘 팔장",
            family: .palgwe,
            introducedAt: .redAdv,
            videos: [
                VideoResource(
                    url: youtube("XCr8R-yKgvU"),
                    source: VideoSource.spartaTKD,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
    ]

    // MARK: - Poom

    private static let poom: [TKDForm] = [
        TKDForm(
            id: FormID.hwarang,
            name: "Hwarang",
            koreanName: "화랑",
            family: .poom,
            introducedAt: .poom,
            videos: [],
            notes: nil
        ),
    ]

    // MARK: - Black Belt

    private static let blackBelt: [TKDForm] = [
        TKDForm(
            id: FormID.koryo,
            name: "Koryo",
            koreanName: "고려",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("FOS0cXB8vZ8"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.keumgang,
            name: "Keumgang",
            koreanName: "금강",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("UZ3Cm_wlV-A"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.taebaek,
            name: "Taebaek",
            koreanName: "태백",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("FCVlTtEc_wo"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.pyongwon,
            name: "Pyongwon",
            koreanName: "평원",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("nxC46BW4sUg"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.sipjin,
            name: "Sipjin",
            koreanName: "십진",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("Yv9wLnnTt8g"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.jitae,
            name: "Jitae",
            koreanName: "지태",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("55Rfa_WVRZY"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.cheonkwon,
            name: "Cheonkwon",
            koreanName: "천권",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("-oyNEzqPvyA"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.hansu,
            name: "Hansu",
            koreanName: "한수",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("o-Gwkol3fvc"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: FormID.ilyo,
            name: "Ilyo",
            koreanName: "일여",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: youtube("jeZxhYwY--U"),
                    source: VideoSource.kukkiwon,
                    isPrimary: true
                )
            ],
            notes: nil
        ),
    ]
}
