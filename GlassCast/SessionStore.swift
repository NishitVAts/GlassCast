import Foundation
import Supabase

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isRestoring = true

    var userId: UUID? {
        session?.user.id
    }

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func restore() async {
        defer { isRestoring = false }
        do {
            session = try await client.auth.session
        } catch {
            session = nil
        }
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
        session = try await client.auth.session
    }

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
        session = try await client.auth.session
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
        }
        session = nil
    }
}
