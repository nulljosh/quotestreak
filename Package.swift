// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "quotestreak-tui",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/rensbreur/SwiftTUI", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "quotestreak-tui",
            dependencies: ["SwiftTUI"],
            path: "tui"
        )
    ]
)
