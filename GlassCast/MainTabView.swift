import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionStore: SessionStore

    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @AppStorage("selected_city_id") private var selectedCityIdRawValue: String = ""

    private enum Screen {
        case home
        case cities
        case settings
    }

    @State private var isMenuOpen = false
    @State private var screen: Screen = .home

    private let menuWidth: CGFloat = 290

    var body: some View {
        ZStack(alignment: .leading) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: isMenuOpen ? menuWidth : 0)
                .overlay {
                    if isMenuOpen {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                                    isMenuOpen = false
                                }
                            }
                    }
                }

            sideMenu
                .frame(width: menuWidth)
                .offset(x: isMenuOpen ? 0 : -menuWidth)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.92), value: isMenuOpen)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .home:
            HomeView(
                favoritesViewModel: favoritesViewModel,
                sessionStore: sessionStore,
                selectedCityIdRawValue: $selectedCityIdRawValue,
                onMenuTap: toggleMenu
            )
        case .cities:
            CitySearchView(
                favoritesViewModel: favoritesViewModel,
                sessionStore: sessionStore,
                selectedCityIdRawValue: $selectedCityIdRawValue,
                onMenuTap: toggleMenu
            )
        case .settings:
            SettingsView(sessionStore: sessionStore, onMenuTap: toggleMenu)
        }
    }

    private var sideMenu: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GlassCast")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    if let email = sessionStore.session?.user.email {
                        Text(email)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)

                Divider()
                    .overlay(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 10) {
                    menuButton(title: "Home", systemImage: "house", screen: .home)
                    menuButton(title: "Search / Cities", systemImage: "magnifyingglass", screen: .cities)
                    menuButton(title: "Settings", systemImage: "gearshape", screen: .settings)
                }
                .padding(.horizontal, 12)

                Spacer(minLength: 0)

                Button(role: .destructive) {
                    Task { await sessionStore.signOut() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.backward.square")
                        Text("Sign out")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 18)
            }
        }
    }

    private func menuButton(title: String, systemImage: String, screen: Screen) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                self.screen = screen
                isMenuOpen = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(self.screen == screen ? 0.18 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func toggleMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
            isMenuOpen.toggle()
        }
    }
}
