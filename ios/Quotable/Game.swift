import Foundation
import Observation

/// Port of game.js. Scoring, streaks and the speed-round timer live here so the
/// self-check in ios/Checks can drive them without SwiftUI or a real clock.
@Observable
final class Game {
    enum Phase: Equatable { case menu, playing, over }

    static let timeLimit = 10.0
    static let tickInterval = 0.1

    private(set) var quotes: [Quote] = []
    private(set) var phase: Phase = .menu
    private(set) var pool: [Quote] = []
    private(set) var current: Quote?
    private(set) var score = 0
    private(set) var streak = 0
    private(set) var speedMode = false
    private(set) var timeLeft = timeLimit
    /// Set once an answer is picked; nil while the question is open.
    private(set) var pickedAnswer: String?
    private(set) var lastWasCorrect: Bool?
    private(set) var highScore = UserDefaults.standard.integer(forKey: Game.highKey)

    private static let highKey = "quotable_high_score"

    var isAnswered: Bool { pickedAnswer != nil || lastWasCorrect != nil }

    var genres: [String] { Array(Set(quotes.map(\.genre))).sorted() }

    init(quotes: [Quote] = Quote.loadBundled()) {
        self.quotes = quotes
    }

    func start(genre: String?, speed: Bool) {
        speedMode = speed
        score = 0
        streak = 0
        let filtered = genre.map { g in quotes.filter { $0.genre == g } } ?? quotes
        pool = filtered.shuffled()
        phase = .playing
        nextQuestion()
    }

    func nextQuestion() {
        pickedAnswer = nil
        lastWasCorrect = nil
        timeLeft = Self.timeLimit
        guard let next = pool.popLast() else { return endGame() }
        current = next
    }

    /// Points for answering correctly right now. Mirrors game.js: 10, multiplied by the
    /// whole seconds remaining in a speed round (never less than 1x).
    var pendingPoints: Int {
        10 * (speedMode ? max(1, Int(timeLeft.rounded(.up))) : 1)
    }

    /// `answer == nil` is a speed-round timeout, which game.js scores as a miss.
    @discardableResult
    func choose(_ answer: String?) -> Bool {
        guard let current, !isAnswered else { return false }
        let correct = answer == current.answer
        let points = pendingPoints
        pickedAnswer = answer
        lastWasCorrect = correct
        if correct {
            streak += 1
            score += points
        } else {
            streak = 0
        }
        return correct
    }

    /// Advance the speed-round clock. Returns true if this tick timed the question out.
    @discardableResult
    func tick(_ delta: Double = tickInterval) -> Bool {
        guard speedMode, phase == .playing, !isAnswered else { return false }
        timeLeft -= delta
        guard timeLeft <= 0 else { return false }
        timeLeft = 0
        choose(nil)
        return true
    }

    func endGame() {
        current = nil
        phase = .over
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: Self.highKey)
        }
    }

    func backToMenu() {
        phase = .menu
    }
}
