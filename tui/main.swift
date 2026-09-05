import Foundation
import SwiftTUI

// ponytail: shows the quote and the answer, no guessing loop — a keystroke-driven
// game needs a redraw loop this pilot doesn't need to prove the fetch works.
// `quotestreak-tui` pulls one round from the same /api/random the web game uses.

struct Round: Decodable {
    let quote: String
    let answer: String
    let options: [String]
    let genre: String
    let type: String
}

func fetchRound() async -> Round? {
    guard let url = URL(string: "https://quotestreak.heyitsmejosh.com/api/random") else { return nil }
    guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
    return try? JSONDecoder().decode(Round.self, from: data)
}

struct RoundCard: View {
    let round: Round?

    var body: some View {
        VStack(alignment: .leading) {
            Text("quotestreak").bold()
            if let round {
                Text("\"\(round.quote)\"")
                ForEach(round.options, id: \.self) { o in
                    Text(o == round.answer ? "→ \(o)" : "  \(o)")
                }
                Text("\(round.genre) · \(round.type)")
            } else {
                Text("Could not reach quotestreak.heyitsmejosh.com")
            }
        }
        .padding()
        .border()
    }
}

let semaphore = DispatchSemaphore(value: 0)
var round: Round?
Task {
    round = await fetchRound()
    semaphore.signal()
}
semaphore.wait()

Application(rootView: RoundCard(round: round)).start()
