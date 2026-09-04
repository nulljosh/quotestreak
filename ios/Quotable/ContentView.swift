import CoreGraphics
import ImageIO
import Observation
import SwiftUI

struct ContentView: View {
    @State private var game = Game()
    @State private var genre = MenuView.allGenres
    @AppStorage("quotable_haptics_on") private var hapticsOn = true
    @AppStorage("quotable_sfx_on") private var sfxOn = true
    @AppStorage("quotable_sfx_vol") private var sfxVolume = 60.0
    @State private var showAccount = false
    @State private var showBoard = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                switch game.phase {
                case .menu: MenuView(game: game, genre: $genre)
                case .playing: RoundView(game: game, hapticsOn: hapticsOn, sfxOn: sfxOn, sfxVolume: sfxVolume)
                case .over: GameOverView(game: game)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { Backdrop(quotes: game.quotes).ignoresSafeArea() }
            .background(Theme.canvas)
            .navigationTitle("Quotestreak")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showAccount) { AccountSheet() }
            .sheet(isPresented: $showBoard) { LeaderboardSheet(speed: game.speedMode) }
            .sheet(isPresented: $showSettings) { SettingsSheet(hapticsOn: $hapticsOn, sfxOn: $sfxOn, sfxVolume: $sfxVolume) }
            .toolbar {
                if game.phase != .playing {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showBoard = true } label: { Label("Leaderboard", systemImage: "list.number") }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button { showAccount = true } label: { Label("Account", systemImage: "person.crop.circle") }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button { showSettings = true } label: { Label("Settings", systemImage: "gearshape") }
                    }
                }
                if game.phase == .playing {
                    ToolbarItem(placement: .primaryAction) {
                        Text("\(game.score)").monospacedDigit().foregroundStyle(Theme.accent).bold()
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Label("\(game.streak)", systemImage: "flame.fill")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(game.streak > 0 ? .orange : .secondary)
                    }
                }
            }
        }
    }
}

private struct MenuView: View {
    static let allGenres = "All genres"

    let game: Game
    @Binding var genre: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Guess the movie or artist from the quote.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Picker("Genre", selection: $genre) {
                Text(LocalizedStringKey(Self.allGenres)).tag(Self.allGenres)
                ForEach(game.genres, id: \.self) { g in
                    Text(g.capitalized).tag(g)
                }
            }
            .pickerStyle(.menu)

            VStack(spacing: 12) {
                Button("Play") { game.start(genre: selectedGenre, speed: false) }
                    .buttonStyle(.borderedProminent)
                Button("Speed Round (10s)") { game.start(genre: selectedGenre, speed: true) }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .tint(Theme.accent)

            if game.highScore > 0 {
                Text("High score: \(game.highScore)").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(28)
    }

    private var selectedGenre: String? { genre == Self.allGenres ? nil : genre }
}

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hapticsOn: Bool
    @Binding var sfxOn: Bool
    @Binding var sfxVolume: Double

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Haptics", isOn: $hapticsOn)
                Toggle("Sound effects", isOn: $sfxOn)
                if sfxOn {
                    LabeledContent("Volume") {
                        Slider(value: $sfxVolume, in: 0...100)
                    }
                }
            }
            .tint(Theme.accent)
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct RoundView: View {
    let game: Game
    let hapticsOn: Bool
    let sfxOn: Bool
    let sfxVolume: Double

    @State private var flashedArt: URL?
    @State private var flashToken = 0
    @State private var art = ArtLoader()

    private let clock = Timer.publish(every: Game.tickInterval, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            if game.speedMode { TimerRing(timeLeft: game.timeLeft) }

            if let quote = game.current {
                let badge = Theme.badge(for: quote.genre)
                Text(quote.genre.capitalized)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(badge.background, in: Capsule())
                    .foregroundStyle(badge.foreground)

                Text(LocalizedStringKey(quote.prompt)).font(.subheadline.bold()).foregroundStyle(.secondary)

                Text("\u{201C}\(quote.quote)\u{201D}")
                    .font(.title2.italic())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .id(quote.id)
                    .transition(.opacity)

                VStack(spacing: 10) {
                    ForEach(quote.options.shuffledStably(seed: quote.id), id: \.self) { option in
                        Button { answer(option) } label: {
                            Text(option)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(foreground(for: option, answer: quote.answer))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(tint(for: option, answer: quote.answer))
                        // Not .disabled(): a disabled button renders its tint washed out,
                        // which hides the green/red answer reveal.
                        .allowsHitTesting(!game.isAnswered)
                    }
                }

                if let correct = game.lastWasCorrect {
                    Text(correct ? "Correct! +\(game.lastPoints)" : "Nope — it was \u{201C}\(quote.answer)\u{201D}")
                        .font(.headline)
                        .foregroundStyle(correct ? .green : .red)
                }
            }
            Spacer()
        }
        .padding(24)
        .animation(.default, value: game.current)
        .sensoryFeedback(.success, trigger: game.lastWasCorrect) { _, new in hapticsOn && new == true }
        .sensoryFeedback(.error, trigger: game.lastWasCorrect) { _, new in hapticsOn && new == false }
        .onReceive(clock) { _ in
            if game.tick() {
                react(correct: false)
                advanceAfterDelay()
            }
        }
        .background { ArtFlash(url: flashedArt, cached: art.image(for: flashedArt)).ignoresSafeArea().animation(.easeInOut(duration: 0.25), value: flashedArt) }
        .onChange(of: game.current) { _, quote in art.prefetch(quote?.art) }
        .onAppear { art.prefetch(game.current?.art) }
    }

    /// game.js fades the movie poster / album art in as the background on a correct answer.
    private func react(correct: Bool) {
        if sfxOn {
            correct ? Sound.correct(volume: sfxVolume / 100) : Sound.wrong(volume: sfxVolume / 100)
        }
        guard correct, let url = game.current?.art else { return }
        flashedArt = url
        // Back-to-back correct answers: the previous dismiss is still pending and would
        // cut this flash short, so only the newest one is allowed to clear it.
        flashToken += 1
        let token = flashToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            if flashToken == token { flashedArt = nil }
        }
    }

    private func tint(for option: String, answer: String) -> Color {
        guard game.isAnswered else { return Theme.accent }
        if option == answer { return .green }
        return option == game.pickedAnswer ? .red : .gray
    }

    private func foreground(for option: String, answer: String) -> Color {
        guard game.isAnswered else { return Theme.accent }
        if option == answer { return .primary }
        if option == game.pickedAnswer { return .red }
        return .secondary
    }

    private func answer(_ option: String) {
        react(correct: game.choose(option))
        advanceAfterDelay()
    }

    private func advanceAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard game.phase == .playing else { return }
            game.nextQuestion()
        }
    }
}

private struct ArtFlash: View {
    let url: URL?
    let cached: Image?

    // Port of the web `#art-flash`: full-bleed cover at 0.35 opacity behind the content,
    // faded in and out, never a floating card.
    var body: some View {
        if let url {
            Group {
                if let cached {
                    cached.resizable().scaledToFill()
                } else {
                    // Only reached if the prefetch has not landed yet; AsyncImage has the
                    // rest of the 0.95s reveal to catch up.
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.clear
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .opacity(0.35)
            .transition(.opacity)
            .allowsHitTesting(false)
        }
    }
}

private struct TimerRing: View {
    let timeLeft: Double

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0, timeLeft / Game.timeLimit))
                .stroke(Theme.accent, style: .init(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(timeLeft.rounded(.up)))").font(.headline).monospacedDigit()
        }
        .frame(width: 64, height: 64)
    }
}

private struct GameOverView: View {
    let game: Game

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Game Over").font(.largeTitle.bold())
            Text("Final score: \(game.score) · High score: \(game.highScore)").font(.title3)
            Button("Play Again") { game.backToMenu() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.accent)
            ShareLink(item: "I scored \(game.score) on Quotestreak! Can you beat me? https://quotable.heyitsmejosh.com")
            Spacer()
        }
        .padding(28)
        .task { await Account.shared.submit(score: game.score, speed: game.speedMode) }
    }
}

private extension Array {
    /// Shuffle once per question rather than on every SwiftUI body evaluation,
    /// which would reorder the buttons under the user's finger.
    func shuffledStably(seed: String) -> [Element] {
        var generator = SeededGenerator(seed: seed)
        return shuffled(using: &generator)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        state = seed.utf8.reduce(UInt64(0xcbf29ce484222325)) { ($0 ^ UInt64($1)) &* 0x100000001b3 }
        if state == 0 { state = 0x9e3779b97f4a7c15 }
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Artwork is fetched as soon as a question appears, so a correct answer can flash it
/// immediately rather than racing AsyncImage against the 0.95s reveal — the same reason
/// game.js preloads it in nextQuestion(). Decoded via ImageIO so one implementation
/// serves both iOS and macOS without a UIImage/NSImage branch.
@Observable
final class ArtLoader {
    private var cache: [URL: Image] = [:]
    private var inFlight: Set<URL> = []

    func image(for url: URL?) -> Image? {
        guard let url else { return nil }
        return cache[url]
    }

    func prefetch(_ url: URL?) {
        guard let url, cache[url] == nil, !inFlight.contains(url) else { return }
        inFlight.insert(url)
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap(Self.decode)
            DispatchQueue.main.async {
                guard let self else { return }
                self.inFlight.remove(url)
                // A failed load stays uncached: the flash falls back to AsyncImage and,
                // failing that, simply does not appear.
                if let image { self.cache[url] = image }
            }
        }.resume()
    }

    private static func decode(_ data: Data) -> Image? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }
}

/// Port of the web `#backdrop`: a static poster/album mosaic at low opacity behind
/// the whole game. Static on purpose — the speed round is a timed attention task.
private struct Backdrop: View {
    let quotes: [Quote]
    @Environment(\.colorScheme) private var scheme

    private struct Tile: Identifiable {
        let id: URL
        let square: Bool
    }

    /// Thumbnails, not the w500 art the flash uses; deduped; shuffled once per launch.
    private var tiles: [Tile] {
        var seen = Set<URL>()
        return quotes.compactMap { q -> Tile? in
            guard let art = q.art, seen.insert(art).inserted else { return nil }
            let thumb = art.absoluteString
                .replacingOccurrences(of: "/w500/", with: "/w185/")
                .replacingOccurrences(of: "/600x600bb.jpg", with: "/200x200bb.jpg")
            return Tile(id: URL(string: thumb) ?? art, square: q.type == .music)
        }
    }

    var body: some View {
        let all = tiles
        GeometryReader { geo in
            let cols = max(3, Int((geo.size.width / 110).rounded(.up)))
            let per = Int((geo.size.height / 140).rounded(.up)) + 1
            if all.count >= 8 {
                let shuffled = all.shuffledStably(seed: "backdrop")
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<cols, id: \.self) { c in
                        VStack(spacing: 8) {
                            ForEach(0..<per, id: \.self) { r in
                                let t = shuffled[(c * per + r) % shuffled.count]
                                AsyncImage(url: t.id) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                                    .aspectRatio(t.square ? 1 : 2 / 3, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .padding(8)
                .opacity(scheme == .dark ? 0.22 : 0.14)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
