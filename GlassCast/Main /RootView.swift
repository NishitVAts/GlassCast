import SwiftUI

struct RootView: View {
    @StateObject private var sessionStore = SessionStore()

    var body: some View {
        Group {
            if sessionStore.isRestoring {
                ProgressView()
                    .controlSize(.large)
            } else if sessionStore.session == nil {
                AuthView(sessionStore: sessionStore)
            } else {
                MainTabView(sessionStore: sessionStore)
            }
        }
        .task {
            await sessionStore.restore()
        }
    }
}
