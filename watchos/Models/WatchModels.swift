import Foundation

/// Mirrors the keys `SharedStore.swift` writes into the shared App Group
/// container on the iPhone (`group.com.heyitsmejosh.quotable`). Quotestreak
/// has no backend — see root CLAUDE.md ("Static site, no build step, no
/// backend") — so this struct describes the on-device sync payload, not a
/// server response.
struct QuotestreakSummary: Equatable {
    var score: Int
    var streak: Int
    var highScore: Int
    /// Raw value of `Game.Phase` from the iOS app: "menu", "playing", or "over".
    var phase: String
    var updatedAt: Date?

    static let empty = QuotestreakSummary(score: 0, streak: 0, highScore: 0, phase: "menu", updatedAt: nil)

    var hasSynced: Bool { updatedAt != nil }

    var statusLine: String {
        switch phase {
        case "playing": return "Game in progress"
        case "over": return "Game over"
        default: return "Ready to play"
        }
    }
}
