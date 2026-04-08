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

    // MARK: - Keecho

    private static let keecho: [TKDForm] = [
        TKDForm(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Keecho Il Jang",
            koreanName: "기초 일장",
            family: .keecho,
            introducedAt: .white,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=FD9m2KE-9D4")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
            name: "Keecho Ee Jang",
            koreanName: "기초 이장",
            family: .keecho,
            introducedAt: .white,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=gfftpjOn5fY")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!,
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
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000001")!,
            name: "Taegeuk Il Jang",
            koreanName: "태극 일장",
            family: .taegeuk,
            introducedAt: .yellow,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=iCmGecTpzE4")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000002")!,
            name: "Taegeuk Ee Jang",
            koreanName: "태극 이장",
            family: .taegeuk,
            introducedAt: .yellow,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=YB2-yomN1pw")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000003")!,
            name: "Taegeuk Sam Jang",
            koreanName: "태극 삼장",
            family: .taegeuk,
            introducedAt: .green,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=7iREIx5oC4c")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000004")!,
            name: "Taegeuk Sa Jang",
            koreanName: "태극 사장",
            family: .taegeuk,
            introducedAt: .green,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=bhLQfcXy__Q")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000005")!,
            name: "Taegeuk Oh Jang",
            koreanName: "태극 오장",
            family: .taegeuk,
            introducedAt: .blue,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=cRgGd5_mDd8")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000006")!,
            name: "Taegeuk Yuk Jang",
            koreanName: "태극 육장",
            family: .taegeuk,
            introducedAt: .blue,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=UCxVGTbAENU")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000007")!,
            name: "Taegeuk Chil Jang",
            koreanName: "태극 칠장",
            family: .taegeuk,
            introducedAt: .red,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=WjpsIeeGlSA")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000008")!,
            name: "Taegeuk Pal Jang",
            koreanName: "태극 팔장",
            family: .taegeuk,
            introducedAt: .red,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=4IL0hqcs_jE")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
    ]

    // MARK: - Palgwe

    private static let palgwe: [TKDForm] = [
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000001")!,
            name: "Palgwe Il Jang",
            koreanName: "팔괘 일장",
            family: .palgwe,
            introducedAt: .yellow,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=uiLBDwJdQUU")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000002")!,
            name: "Palgwe Ee Jang",
            koreanName: "팔괘 이장",
            family: .palgwe,
            introducedAt: .yellow,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=3jbKCbI-rJA")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000003")!,
            name: "Palgwe Sam Jang",
            koreanName: "팔괘 삼장",
            family: .palgwe,
            introducedAt: .green,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=XJVOHDJLaw0")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000004")!,
            name: "Palgwe Sa Jang",
            koreanName: "팔괘 사장",
            family: .palgwe,
            introducedAt: .green,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=rtZGG5-P0Wo")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000005")!,
            name: "Palgwe Oh Jang",
            koreanName: "팔괘 오장",
            family: .palgwe,
            introducedAt: .blue,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=grRm0Q8rpx8")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000006")!,
            name: "Palgwe Yuk Jang",
            koreanName: "팔괘 육장",
            family: .palgwe,
            introducedAt: .blue,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=veARrGqOxpM")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000007")!,
            name: "Palgwe Chil Jang",
            koreanName: "팔괘 칠장",
            family: .palgwe,
            introducedAt: .red,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=vIcnLp4hPw8")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000008")!,
            name: "Palgwe Pal Jang",
            koreanName: "팔괘 팔장",
            family: .palgwe,
            introducedAt: .red,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=XCr8R-yKgvU")!,
                    source: "Sparta TKD",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
    ]

    // MARK: - Poom

    private static let poom: [TKDForm] = [
        TKDForm(
            id: UUID(uuidString: "00000004-0000-0000-0000-000000000001")!,
            name: "Hwarang",
            koreanName: "화랑",
            family: .poom,
            introducedAt: .poom,
            videos: [],
            notes: nil
        ),
    ]

    // MARK: - Black Belt

    // Known gap: Jitae, Cheonkwon, Hansu, and Ilyo have no YouTube URLs yet.
    // Their UUIDs are reserved so SwiftData history is not disrupted when videos are added.
    private static let blackBelt: [TKDForm] = [
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000001")!,
            name: "Koryo",
            koreanName: "고려",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=FOS0cXB8vZ8")!,
                    source: "Kukkiwon",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000002")!,
            name: "Keumgang",
            koreanName: "금강",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=UZ3Cm_wlV-A")!,
                    source: "Kukkiwon",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000003")!,
            name: "Taebaek",
            koreanName: "태백",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=FCVlTtEc_wo")!,
                    source: "Kukkiwon",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000004")!,
            name: "Pyongwon",
            koreanName: "평원",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=nxC46BW4sUg")!,
                    source: "Kukkiwon",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000005")!,
            name: "Sipjin",
            koreanName: "십진",
            family: .blackBelt,
            introducedAt: .black,
            videos: [
                VideoResource(
                    url: URL(string: "https://www.youtube.com/watch?v=Yv9wLnnTt8g")!,
                    source: "Kukkiwon",
                    isPrimary: true
                )
            ],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000006")!,
            name: "Jitae",
            koreanName: "지태",
            family: .blackBelt,
            introducedAt: .black,
            videos: [],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000007")!,
            name: "Cheonkwon",
            koreanName: "천권",
            family: .blackBelt,
            introducedAt: .black,
            videos: [],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000008")!,
            name: "Hansu",
            koreanName: "한수",
            family: .blackBelt,
            introducedAt: .black,
            videos: [],
            notes: nil
        ),
        TKDForm(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000009")!,
            name: "Ilyo",
            koreanName: "일여",
            family: .blackBelt,
            introducedAt: .black,
            videos: [],
            notes: nil
        ),
    ]
}
