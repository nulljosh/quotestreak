import SwiftUI

@main
struct QuotableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 480, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
    }
}
