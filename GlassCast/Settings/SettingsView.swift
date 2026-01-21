import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionStore: SessionStore

    let onMenuTap: () -> Void

    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureUnit.celsius.rawValue

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.98).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.spacingLG) {
                        // Temperature Unit Section
                        settingsCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                                HStack(spacing: AppTheme.spacingSM) {
                                    Image(systemName: "thermometer.medium")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(width: 36, height: 36)
                                        .background(AppTheme.accent.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Temperature Unit")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Choose how temperatures are displayed")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Picker("Temperature", selection: $temperatureUnitRawValue) {
                                    ForEach(TemperatureUnit.allCases) { unit in
                                        Text(unit.displayName).tag(unit.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Account Section
                        settingsCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                                HStack(spacing: AppTheme.spacingSM) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.blue)
                                        .frame(width: 36, height: 36)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Account")
                                            .font(.system(size: 16, weight: .semibold))
                                        if let email = sessionStore.session?.user.email {
                                            Text(email)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                
                                Text("Your saved cities are stored in your account. Sign out anytime—just sign back in to restore them.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                Button {
                                    Task { await sessionStore.signOut() }
                                    Haptics.warning()
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Sign Out")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.9, green: 0.3, blue: 0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                                }
                                .buttonStyle(PressScaleButtonStyle())
                            }
                        }
                        
                        // App Info
                        VStack(spacing: AppTheme.spacingSM) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppTheme.accent)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("GlassCast")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            
                            Text("Version 1.0")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppTheme.spacingLG)
                    }
                    .padding(.horizontal, AppTheme.spacingLG)
                    .padding(.top, AppTheme.spacingMD)
                    .padding(.bottom, AppTheme.spacingXL)
                }
            }
        }
        .onChange(of: temperatureUnitRawValue) { _ in
            Haptics.light()
        }
    }
    
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(AppTheme.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var topBar: some View {
        HStack {
            Button {
                onMenuTap()
                Haptics.medium()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer(minLength: 0)

            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.spacingSM)
        .padding(.top, AppTheme.spacingSM)
        .padding(.bottom, AppTheme.spacingSM)
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius
    case fahrenheit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}
