import SwiftUI

/// The main watch face: high score, the last round played, and whether a
/// round is currently in progress on the iPhone. All three numbers are real
/// fields from `Game.swift` (`score`, `streak`, `highScore`) — nothing here
/// is invented to fill space.
struct StreakGlance: View {
    @State private var summary: QuotestreakSummary = .empty

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Quotestreak")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if summary.hasSynced {
                    VStack(spacing: 2) {
                        Text("\(summary.highScore)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("High score").font(.caption).foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        VStack {
                            Text("\(summary.score)").font(.title3.bold()).monospacedDigit()
                            Text("Last score").font(.caption2).foregroundStyle(.secondary)
                        }
                        VStack {
                            Label("\(summary.streak)", systemImage: "flame.fill")
                                .font(.title3.bold())
                                .monospacedDigit()
                                .foregroundStyle(summary.streak > 0 ? .orange : .secondary)
                            Text("Streak").font(.caption2).foregroundStyle(.secondary)
                        }
                    }

                    Text(summary.statusLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let updatedAt = summary.updatedAt {
                        Text("Synced \(updatedAt, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("Play a round on your iPhone to sync your score here.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                Button("Refresh", action: refresh)
                    .font(.caption2)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 4)
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        summary = WatchAPI.shared.fetchSummary()
    }
}
