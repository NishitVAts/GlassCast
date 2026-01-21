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
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.12),
                    Color(red: 0.12, green: 0.14, blue: 0.28),
                    Color(red: 0.06, green: 0.06, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: AppTheme.spacingLG) {
                    VStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("GlassCast")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text(isLogin ? "Welcome back" : "Create your account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, AppTheme.spacingMD)

                    VStack(spacing: AppTheme.spacingMD) {
                        VStack(spacing: AppTheme.spacingSM) {
                            Text("Email")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("", text: $email, prompt: Text("you@example.com").foregroundStyle(.white.opacity(0.35)))
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                }
                        }
                        
                        VStack(spacing: AppTheme.spacingSM) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            SecureField("", text: $password, prompt: Text("••••••••").foregroundStyle(.white.opacity(0.35)))
                                .textContentType(.password)
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                }
                        }

                        if let errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    VStack(spacing: AppTheme.spacingMD) {
                        Button {
                            Task { await submit() }
                            Haptics.medium()
                        } label: {
                            HStack(spacing: 10) {
                                if isWorking {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text(isLogin ? "Sign In" : "Create Account")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                        }
                        .buttonStyle(PressScaleButtonStyle())
                        .disabled(isWorking)

                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isLogin.toggle()
                                errorMessage = nil
                            }
                            Haptics.light()
                        } label: {
                            HStack(spacing: 4) {
                                Text(isLogin ? "Don't have an account?" : "Already have an account?")
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(isLogin ? "Sign up" : "Sign in")
                                    .foregroundStyle(AppTheme.accent)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 14))
                        }
                    }
                }
                .padding(AppTheme.spacingLG)
                .background(.ultraThinMaterial.opacity(0.5))
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
                .padding(.horizontal, AppTheme.spacingLG)
                
                Spacer()
                
                Text("Your weather, beautifully.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, AppTheme.spacingXL)
            }
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
