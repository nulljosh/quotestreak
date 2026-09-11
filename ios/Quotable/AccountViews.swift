import AuthenticationServices
import SwiftUI

struct AccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var deletingAccount = false
    private var account: Account { Account.shared }

    var body: some View {
        VStack(spacing: 20) {
            Text("Account").font(.title2.bold())
            if account.isSignedIn {
                Text("Signed in as \(account.name)")
                Button("Sign out") { account.signOut() }
                Button("Delete account", role: .destructive) { confirmingDelete = true }
                    .disabled(deletingAccount)
            } else {
                Text("Sign in to put your scores on the leaderboard.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                SignInWithAppleButton(.signIn, onRequest: account.prepare) { result in
                    Task { await account.finish(result); dismiss() }
                }
                .frame(width: 260, height: 44)

                Button {
                    Task { await account.signInWithGoogle(); dismiss() }
                } label: {
                    Text("Continue with Google")
                        .fontWeight(.semibold)
                        .frame(width: 260)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            Button("Close") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(28)
        .frame(minWidth: 320)
        .confirmationDialog("Delete account?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                deletingAccount = true
                Task { if await account.deleteAccount() { dismiss() }; deletingAccount = false }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and score history. This cannot be undone.")
        }
    }
}

struct LeaderboardSheet: View {
    let speed: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [Account.Entry]?

    var body: some View {
        VStack(spacing: 16) {
            Text(speed ? "Speed Round leaders" : "Leaders").font(.title2.bold())
            if let entries {
                if entries.isEmpty {
                    Text("No scores yet. Sign in and play!").foregroundStyle(.secondary)
                } else {
                    List(Array(entries.enumerated()), id: \.offset) { i, e in
                        HStack {
                            Text("\(i + 1).").foregroundStyle(.secondary).monospacedDigit()
                            Text(e.name)
                            Spacer()
                            Text("\(e.score)").monospacedDigit().bold()
                        }
                    }
                    .frame(minHeight: 300)
                }
            } else {
                ProgressView()
            }
            Button("Close") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(28)
        .frame(minWidth: 320)
        .task { entries = await Account.shared.leaderboard(speed: speed) }
    }
}
