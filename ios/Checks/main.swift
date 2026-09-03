// Quote-bank + scoring self-check. The only non-trivial logic in the app.
//
//   swiftc -o /tmp/quotablecheck ios/Quotable/Quote.swift ios/Quotable/Game.swift ios/Quotable/SharedStore.swift ios/Checks/main.swift \
//     && /tmp/quotablecheck quotes.json

import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    checks += 1
    guard condition() else {
        FileHandle.standardError.write("FAIL: \(label)\n".data(using: .utf8)!)
        exit(1)
    }
}

let path = CommandLine.arguments.dropFirst().first ?? "quotes.json"
guard let data = FileManager.default.contents(atPath: path),
      let quotes = try? JSONDecoder().decode([Quote].self, from: data) else {
    FileHandle.standardError.write("FAIL: could not decode \(path)\n".data(using: .utf8)!)
    exit(1)
}

// --- quote bank ---
check(quotes.count > 250, "bank has \(quotes.count) entries, expected > 250")
var seen = Set<String>()
for q in quotes {
    check(q.options.count == 4, "\(q.answer): \(q.options.count) options, expected 4")
    check(Set(q.options).count == 4, "\(q.answer): duplicate options \(q.options)")
    check(q.options.contains(q.answer), "\(q.answer): answer missing from options")
    check(!q.quote.trimmingCharacters(in: .whitespaces).isEmpty, "empty quote for \(q.answer)")
    check(seen.insert(q.quote.lowercased()).inserted, "duplicate quote: \(q.quote)")
    if q.type == .movie { check(q.year != nil, "\(q.answer): movie entry without a year") }
}

// --- scoring ---
let sample = quotes[0]
let normal = Game(quotes: [sample])
normal.start(genre: nil, speed: false)
check(normal.choose(sample.answer), "correct answer not scored as correct")
check(normal.score == 10, "normal round scored \(normal.score), expected 10")
check(normal.streak == 1, "streak did not increment")

let miss = Game(quotes: [sample])
miss.start(genre: nil, speed: false)
_ = miss.choose(sample.answer)
miss.nextQuestion()          // pool is empty -> endGame, but streak must survive a wrong pick first
let streakBreak = Game(quotes: [sample])
streakBreak.start(genre: nil, speed: false)
_ = streakBreak.choose(sample.answer)
check(streakBreak.streak == 1, "setup: streak should be 1")
let wrongOption = sample.options.first { $0 != sample.answer }!
let second = Game(quotes: [sample])
second.start(genre: nil, speed: false)
check(second.choose(wrongOption) == false, "wrong answer scored as correct")
check(second.score == 0, "wrong answer awarded \(second.score) points")
check(second.streak == 0, "streak not reset on a miss")

// Speed round: full clock is a 10x multiplier, and the clock running out is a miss.
let speed = Game(quotes: [sample])
speed.start(genre: nil, speed: true)
check(speed.pendingPoints == 100, "full-clock bonus was \(speed.pendingPoints), expected 100")
_ = speed.choose(sample.answer)
check(speed.score == 100, "speed round scored \(speed.score), expected 100")

let timeout = Game(quotes: [sample])
timeout.start(genre: nil, speed: true)
var ticks = 0
while !timeout.isAnswered && ticks < 1000 { _ = timeout.tick(); ticks += 1 }
check(timeout.isAnswered, "clock never timed the question out")
check(timeout.score == 0, "timeout awarded \(timeout.score) points")
check(timeout.streak == 0, "timeout did not reset streak")

// Late ticks must not double-answer or drive the score negative.
_ = timeout.tick()
check(timeout.score == 0, "tick after answer changed the score")

// Genre filter only deals the requested genre.
let genre = quotes[0].genre
let filtered = Game(quotes: quotes)
filtered.start(genre: genre, speed: false)
check(filtered.current?.genre == genre, "genre filter dealt the wrong genre")

print("ok — \(checks) checks, \(quotes.count) quotes")
