import Foundation

/// Mirrors game state into the shared App Group container
/// (`group.com.heyitsmejosh.quotable`) so the watchOS companion can show a
/// summary without its own network layer — Quotestreak has no backend (see
/// root CLAUDE.md). Called from `Game.swift` whenever score, streak, or
/// phase change.
enum SharedStore {
    private static let suiteName = "group.com.heyitsmejosh.quotable"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    static func sync(score: Int, streak: Int, highScore: Int, phase: Game.Phase) {
        guard let defaults else { return }
        defaults.set(score, forKey: "shared_score")
        defaults.set(streak, forKey: "shared_streak")
        defaults.set(highScore, forKey: "shared_high_score")
        defaults.set(label(for: phase), forKey: "shared_phase")
        defaults.set(Date().timeIntervalSince1970, forKey: "shared_updated_at")
    }

    private static func label(for phase: Game.Phase) -> String {
        switch phase {
        case .menu: return "menu"
        case .playing: return "playing"
        case .over: return "over"
        }
    }
}
