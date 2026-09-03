import SwiftUI

/// The one extra tab. Quotestreak has no account system and no API token to
/// pair (see `WatchAPI.swift`), so there is nothing to type in here — this
/// replaces what would otherwise be a pairing screen with a short, honest
/// explanation of how the sync actually works.
struct SyncInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Label("How sync works", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)

                Text("Quotestreak has no account or server. This watch app reads the score, streak, and high score straight from your iPhone's copy of the app, shared through an App Group.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Open Quotestreak on your iPhone and play a round to update what's shown here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}
