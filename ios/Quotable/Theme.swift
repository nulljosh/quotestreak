// Colors lifted from style.css so the app and the web game read as one product.

import SwiftUI

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

enum Theme {
    /// The window/page ground. `.systemBackground` is UIKit-only.
    static var canvas: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    static let accent = Color(hex: "5B9BD5")
    static let accent2 = Color(hex: "3d7bb8")

    /// `--g-*` / `--g-*-text` pairs from style.css. Unknown genres fall back to accent.
    static func badge(for genre: String) -> (background: Color, foreground: Color) {
        switch genre {
        case "action":  return (Color(hex: "ff6b35"), .black)
        case "comedy":  return (Color(hex: "ffd23f"), .black)
        case "drama":   return (Color(hex: "3d5aa8"), .white)
        case "scifi":   return (Color(hex: "b3312c"), .white)
        case "classic": return (Color(hex: "c9a24b"), .black)
        case "pop":     return (Color(hex: "ff6fae"), .black)
        case "rock":    return (Color(hex: "6b7280"), .white)
        case "hiphop":  return (Color(hex: "2e8b57"), .white)
        case "rnb":     return (Color(hex: "b8860b"), .black)
        case "country": return (Color(hex: "8b5a2b"), .white)
        default:        return (accent, .white)
        }
    }
}
