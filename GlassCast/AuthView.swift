import SwiftUI

struct AuthView: View {
    @ObservedObject var sessionStore: SessionStore

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""

    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.blue.opacity(0.35), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("GlassCast")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                    Text(isLogin ? "Sign in" : "Create account")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isWorking {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isLogin ? "Login" : "Sign up")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.14))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(isWorking)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isLogin.toggle()
                            errorMessage = nil
                        }
                    } label: {
                        Text(isLogin ? "Don’t have an account? Sign up" : "Already have an account? Login")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    private func submit() async {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Email is required."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            if isLogin {
                try await sessionStore.signIn(email: email, password: password)
            } else {
                try await sessionStore.signUp(email: email, password: password)
            }
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
