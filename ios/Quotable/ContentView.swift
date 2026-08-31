import SwiftUI

struct ContentView: View {
    @State private var game = Game()
    @State private var genre = MenuView.allGenres
    @AppStorage("quotable_haptics_on") private var hapticsOn = true
    @AppStorage("quotable_sfx_on") private var sfxOn = true
    @AppStorage("quotable_sfx_vol") private var sfxVolume = 60.0

    var body: some View {
        NavigationStack {
            Group {
                switch game.phase {
                case .menu: MenuView(game: game, genre: $genre, hapticsOn: $hapticsOn, sfxOn: $sfxOn, sfxVolume: $sfxVolume)
                case .playing: RoundView(game: game, hapticsOn: hapticsOn, sfxOn: sfxOn, sfxVolume: sfxVolume)
                case .over: GameOverView(game: game)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.canvas)
            .navigationTitle("Quotestreak")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
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
    @Binding var hapticsOn: Bool
    @Binding var sfxOn: Bool
    @Binding var sfxVolume: Double

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

            VStack(spacing: 12) {
                Toggle("Haptics", isOn: $hapticsOn)
                Toggle("Sound effects", isOn: $sfxOn)
                if sfxOn {
                    // Matches the web settings panel's 0-100 volume slider.
                    LabeledContent("Volume") {
                        Slider(value: $sfxVolume, in: 0...100)
                    }
                }
            }
            .tint(Theme.accent)
            .frame(maxWidth: 320)

            if game.highScore > 0 {
                Text("High score: \(game.highScore)").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(28)
    }

    private var selectedGenre: String? { genre == Self.allGenres ? nil : genre }
}

private struct RoundView: View {
    let game: Game
    let hapticsOn: Bool
    let sfxOn: Bool
    let sfxVolume: Double

    @State private var flashedArt: URL?

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
        .overlay { ArtFlash(url: flashedArt) }
    }

    /// game.js flashes the movie poster / album art on a correct answer, then fades it out.
    private func react(correct: Bool) {
        if sfxOn {
            correct ? Sound.correct(volume: sfxVolume / 100) : Sound.wrong(volume: sfxVolume / 100)
        }
        guard correct, let art = game.current?.art else { return }
        flashedArt = art
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { flashedArt = nil }
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

    var body: some View {
        if let url {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Color.clear
            }
            .frame(maxWidth: 260, maxHeight: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 20)
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
    }
}

private extension Array where Element == String {
    /// Shuffle once per question rather than on every SwiftUI body evaluation,
    /// which would reorder the buttons under the user's finger.
    func shuffledStably(seed: String) -> [String] {
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
