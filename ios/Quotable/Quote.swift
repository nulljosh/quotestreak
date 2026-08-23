import Foundation

/// One entry of `quotes.json`. The schema is shared verbatim with the web game —
/// do not diverge it; `CLAUDE.md` requires the same file in both places.
struct Quote: Decodable, Identifiable, Equatable {
    enum Kind: String, Decodable { case movie, music }

    let quote: String
    let answer: String
    let options: [String]
    let genre: String
    let type: Kind
    let year: Int?
    let art: URL?

    var id: String { quote }

    /// Prompt text, mirroring `game.js` nextQuestion().
    var prompt: String {
        type == .music ? "Guess the artist from the lyric." : "Guess the movie from the quote."
    }

    static func loadBundled() -> [Quote] {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data)
        else { return [] }
        return quotes
    }
}
