import SwiftUI

extension Color {
    /// Parses a CSS hex string (`"#RRGGBB"` or `"RRGGBB"`) into a SwiftUI Color.
    /// Strips a leading `#` so callers never need to pre-process the value from BeltLevel.colorHex.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
