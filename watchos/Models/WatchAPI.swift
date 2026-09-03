import Foundation

/// Named `WatchAPI` to match the talli/sparkjar watch companions, but
/// Quotestreak's iOS app has no backend to call (root CLAUDE.md: "Static
/// site, no build step, no backend" — profiles/accounts are explicitly
/// "deferred, not yet implemented"). There is nothing to authenticate
/// against, so unlike talli/sparkjar this holds no `apiToken` and there is
/// no pairing step: it just reads the shared App Group container that the
/// iPhone app's `SharedStore.swift` writes to whenever a round starts,
/// scores, or ends. That container is kept in sync between a paired
/// iPhone and Watch by the system, the same mechanism WidgetKit complications
/// use, so this is a real, functional read of on-device data rather than a
/// stub.
final class WatchAPI: @unchecked Sendable {
    static let shared = WatchAPI()

    private static let suiteName = "group.com.heyitsmejosh.quotable"
    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: Self.suiteName)
    }

    /// Reads the latest summary written by the iPhone app. Returns `.empty`
    /// (with `hasSynced == false`) if the iPhone app has never run since the
    /// watch app was paired, so the Watch view can prompt the user to open
    /// the app on their phone instead of showing fabricated zeros as if they
    /// were live data.
    func fetchSummary() -> QuotestreakSummary {
        guard let defaults, let updated = defaults.object(forKey: "shared_updated_at") as? Double else {
            return .empty
        }
        return QuotestreakSummary(
            score: defaults.integer(forKey: "shared_score"),
            streak: defaults.integer(forKey: "shared_streak"),
            highScore: defaults.integer(forKey: "shared_high_score"),
            phase: defaults.string(forKey: "shared_phase") ?? "menu",
            updatedAt: Date(timeIntervalSince1970: updated)
        )
    }
}
