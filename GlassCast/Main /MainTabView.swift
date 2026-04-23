import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionStore: SessionStore

    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @AppStorage("selected_city_id") private var selectedCityIdRawValue: String = ""

    private enum Screen: CaseIterable {
        case home
        case assistant
        case cities
        case settings
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .assistant: return "AI Assistant"
            case .cities: return "Cities"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .assistant: return "sparkles"
            case .cities: return "map.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    @State private var isMenuOpen = false
    @State private var screen: Screen = .home

    private let menuWidth: CGFloat = 280

    var body: some View {
        ZStack(alignment: .leading) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: isMenuOpen ? menuWidth : 0)
                .scaleEffect(isMenuOpen ? 0.92 : 1, anchor: .trailing)
                .overlay {
                    if isMenuOpen {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture { closeMenu() }
                    }
                }
                .disabled(isMenuOpen)

            sideMenu
                .frame(width: menuWidth)
                .offset(x: isMenuOpen ? 0 : -menuWidth - 20)
                .opacity(isMenuOpen ? 1 : 0)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isMenuOpen)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .home:
            HomeView(
                favoritesViewModel: favoritesViewModel,
                sessionStore: sessionStore,
                selectedCityIdRawValue: $selectedCityIdRawValue,
                onMenuTap: toggleMenu,
                viewModel: homeViewModel
            )
        case .assistant:
            AIAssistantView(
                onMenuTap: toggleMenu,
                temperature: homeViewModel.temperatureText,
                condition: homeViewModel.conditionText,
                humidity: homeViewModel.humidityText
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
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.accent)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("GlassCast")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    if let email = sessionStore.session?.user.email {
                        Text(email)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                .padding(.top, AppTheme.spacingXL)
                .padding(.horizontal, AppTheme.spacingLG)
                .padding(.bottom, AppTheme.spacingLG)

                // Navigation
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    ForEach(Screen.allCases, id: \.self) { item in
                        menuButton(item: item)
                    }
                }
                .padding(.horizontal, AppTheme.spacingMD)

                Spacer(minLength: 0)
                
                // Footer
                VStack(spacing: AppTheme.spacingMD) {
                    Divider()
                        .overlay(Color.white.opacity(0.1))
                    
                    Button {
                        Task { await sessionStore.signOut() }
                        Haptics.warning()
                    } label: {
                        HStack(spacing: AppTheme.spacingSM) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, AppTheme.spacingMD)
                .padding(.bottom, AppTheme.spacingXL)
            }
        }
    }

    private func menuButton(item: Screen) -> some View {
        let isActive = screen == item
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                screen = item
                isMenuOpen = false
            }
            Haptics.light()
        } label: {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isActive ? AppTheme.accent : .white.opacity(0.7))
                    .frame(width: 28)
                
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.7))
                
                Spacer()
                
                if isActive {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(isActive ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func toggleMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isMenuOpen.toggle()
        }
        Haptics.medium()
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            isMenuOpen = false
        }
    }
}
