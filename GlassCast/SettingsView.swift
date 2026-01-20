import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionStore: SessionStore

    let onMenuTap: () -> Void

    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureUnit.celsius.rawValue

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                List {
                    Section {
                        Picker("Temperature", selection: $temperatureUnitRawValue) {
                            ForEach(TemperatureUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Button(role: .destructive) {
                            Task { await sessionStore.signOut() }
                        } label: {
                            Text("Sign out")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onMenuTap()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }

            Spacer(minLength: 0)

            Text("Settings")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.black)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
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
