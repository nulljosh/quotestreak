import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StreakGlance()
            SyncInfoView()
        }
        .tabViewStyle(.verticalPage)
    }
}
