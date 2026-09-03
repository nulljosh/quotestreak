import AuthenticationServices
import CryptoKit
import Foundation
import Observation

/// Supabase over plain URLSession: Sign in with Apple (native id_token grant, no .p8 needed),
/// score submission, and the leaderboard view. Shared with macOS via project.yml.
@Observable
final class Account {
    static let shared = Account()

    struct Entry: Decodable, Identifiable {
        let name: String
        let score: Int
        var id: String { name + "\(score)" }
    }

    private static let url = URL(string: "https://tjsxsqlxjmanwvmywwvw.supabase.co")!
    private static let anon = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqc3hzcWx4am1hbnd2bXl3d3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0OTc0MDEsImV4cCI6MjA4NjA3MzQwMX0.LphLfho3wdQC20MhtcnBpzQUNuBoTOobrugQbNGxc68"

    // ponytail: session in UserDefaults, not Keychain. Move to Keychain if the token ever guards more than a leaderboard row.
    private(set) var accessToken: String? = UserDefaults.standard.string(forKey: "sb_access")
    private var refreshToken: String? = UserDefaults.standard.string(forKey: "sb_refresh")
    private(set) var userID: String? = UserDefaults.standard.string(forKey: "sb_user")
    private(set) var name: String = UserDefaults.standard.string(forKey: "sb_name") ?? "Player"
    var isSignedIn: Bool { accessToken != nil }
    /// Raw nonce for the in-flight Apple request; Apple gets its SHA-256.
    private var nonce = ""

    // MARK: Sign in with Apple

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        nonce = UUID().uuidString
        request.requestedScopes = [.fullName]
        request.nonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func finish(_ result: Result<ASAuthorization, Error>) async {
        guard case .success(let auth) = result,
              let cred = auth.credential as? ASAuthorizationAppleIDCredential,
              let token = cred.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else { return }
        // Apple only sends the name on the very first authorization; keep it if we get it.
        if let given = cred.fullName?.givenName, !given.isEmpty {
            name = String(given.prefix(24))
            UserDefaults.standard.set(name, forKey: "sb_name")
        }
        var req = URLRequest(url: Self.url.appending(path: "auth/v1/token").appending(queryItems: [.init(name: "grant_type", value: "id_token")]))
        req.httpMethod = "POST"
        req.setValue(Self.anon, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["provider": "apple", "id_token": token, "nonce": nonce])
        await session(from: req)
    }

    func signOut() {
        accessToken = nil; refreshToken = nil; userID = nil
        for k in ["sb_access", "sb_refresh", "sb_user"] { UserDefaults.standard.removeObject(forKey: k) }
    }

    private struct Session: Decodable {
        let access_token: String, refresh_token: String
        let user: User
        struct User: Decodable { let id: String }
    }

    private func session(from req: URLRequest) async {
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let s = try? JSONDecoder().decode(Session.self, from: data) else { return }
        accessToken = s.access_token; refreshToken = s.refresh_token; userID = s.user.id
        UserDefaults.standard.set(s.access_token, forKey: "sb_access")
        UserDefaults.standard.set(s.refresh_token, forKey: "sb_refresh")
        UserDefaults.standard.set(s.user.id, forKey: "sb_user")
    }

    private func refresh() async {
        guard let refreshToken else { return }
        var req = URLRequest(url: Self.url.appending(path: "auth/v1/token").appending(queryItems: [.init(name: "grant_type", value: "refresh_token")]))
        req.httpMethod = "POST"
        req.setValue(Self.anon, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])
        await session(from: req)
    }

    // MARK: Scores

    func submit(score: Int, speed: Bool) async {
        guard score > 0, isSignedIn else { return }
        if await post(score: score, speed: speed) == 401 {
            await refresh()
            _ = await post(score: score, speed: speed)
        }
    }

    private func post(score: Int, speed: Bool) async -> Int {
        guard let accessToken, let userID else { return 401 }
        var req = URLRequest(url: Self.url.appending(path: "rest/v1/quotestreak_scores"))
        req.httpMethod = "POST"
        req.setValue(Self.anon, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": userID, "name": name, "score": score, "mode": speed ? "speed" : "normal"])
        let status = (try? await URLSession.shared.data(for: req))?.1 as? HTTPURLResponse
        return status?.statusCode ?? 0
    }

    func leaderboard(speed: Bool) async -> [Entry] {
        var req = URLRequest(url: Self.url.appending(path: "rest/v1/quotestreak_leaderboard").appending(queryItems: [
            .init(name: "select", value: "name,score"),
            .init(name: "mode", value: "eq.\(speed ? "speed" : "normal")"),
            .init(name: "order", value: "score.desc"),
            .init(name: "limit", value: "20"),
        ]))
        req.setValue(Self.anon, forHTTPHeaderField: "apikey")
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }
}
