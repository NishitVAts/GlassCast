import SwiftUI

struct CitySearchView: View {
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var sessionStore: SessionStore
    @Binding var selectedCityIdRawValue: String

    let onMenuTap: () -> Void

    @StateObject private var searchViewModel = CitySearchViewModel()
    @FocusState private var isSearchFocused: Bool
    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureUnit.celsius.rawValue

    var body: some View {
        let gradient = WeatherIconMapper.themeGradient(for: "clear")
        let fg = WeatherIconMapper.themeForeground(for: "clear")

        ZStack {
            gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(foreground: fg)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                        searchField

                        if let message = favoritesViewModel.errorMessage {
                            errorBanner(message: message)
                        }

                        favoritesSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: favoritesViewModel.favorites.count)

                        resultsSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: searchViewModel.results.count)
                    }
                    .padding(.horizontal, AppTheme.spacingLG)
                    .padding(.top, AppTheme.spacingMD)
                    .padding(.bottom, AppTheme.spacingXL)
                }
            }
        }
        .task {
            guard let userId = sessionStore.userId else { return }
            await favoritesViewModel.load(userId: userId)
        }
    }

    private func topBar(foreground: Color) -> some View {
        HStack {
            Button {
                onMenuTap()
                Haptics.medium()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer(minLength: 0)

            Text("Cities")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.spacingSM)
        .padding(.top, AppTheme.spacingSM)
        .padding(.bottom, AppTheme.spacingSM)
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            TextField("", text: $searchViewModel.query, prompt: Text("Search cities...").foregroundStyle(.white.opacity(0.4)))
                .focused($isSearchFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .foregroundStyle(.white)
                .onSubmit {
                    Task { await searchViewModel.search() }
                }

            if !searchViewModel.query.isEmpty {
                Button {
                    searchViewModel.query = ""
                    Haptics.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(AppTheme.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
    }
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color(red: 0.9, green: 0.3, blue: 0.3))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text("Favorites")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                
                if !favoritesViewModel.favorites.isEmpty {
                    Text("\(favoritesViewModel.favorites.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardDark)
                        .clipShape(Capsule())
                }
            }

            if favoritesViewModel.favorites.isEmpty {
                emptyFavoritesCard
            } else {
                VStack(spacing: AppTheme.spacingSM) {
                    ForEach(favoritesViewModel.favorites) { city in
                        favoriteRow(city: city)
                    }
                }
            }
        }
    }
    
    private var emptyFavoritesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.accent)
                Text("No favorites yet")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            
            Text("Search for a city and tap + to add it here.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingMD)
        .background(AppTheme.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text("Search Results")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                Spacer()
                if searchViewModel.isSearching {
                    ProgressView()
                        .tint(.black)
                }
            }

            if let message = searchViewModel.errorMessage {
                errorBanner(message: message)
            }

            if searchViewModel.results.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    if searchViewModel.query.isEmpty {
                        Text("Try searching for a city like \"London\" or \"Tokyo\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black.opacity(0.6))
                    } else if !searchViewModel.isSearching {
                        Text("No cities found for \"\(searchViewModel.query)\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
            } else {
                VStack(spacing: AppTheme.spacingSM) {
                    ForEach(searchViewModel.results) { result in
                        resultRow(result: result)
                    }
                }
            }
        }
    }

    private func favoriteRow(city: FavoriteCity) -> some View {
        let isSelected = selectedCityIdRawValue == city.id.uuidString

        return HStack(spacing: AppTheme.spacingSM) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(city.city_name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                Text(String(format: "%.2f, %.2f", city.lat, city.lon))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer(minLength: 0)

            Button {
                guard let userId = sessionStore.userId else { return }
                guard let idx = favoritesViewModel.favorites.firstIndex(where: { $0.id == city.id }) else { return }
                Task { await favoritesViewModel.delete(at: IndexSet(integer: idx), userId: userId) }
                Haptics.warning()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(AppTheme.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                    .strokeBorder(AppTheme.accent.opacity(0.5), lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCityIdRawValue = city.id.uuidString
            Task { await updateWidget(for: city) }
            Haptics.light()
        }
    }

    private var unit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }

    private func updateWidget(for city: FavoriteCity) async {
        let vm = HomeViewModel()
        vm.selectedCity = city
        await vm.refresh(unit: unit)
    }

    private func resultRow(result: GeocodingResult) -> some View {
        Button {
            guard let userId = sessionStore.userId else { return }
            Task { await favoritesViewModel.add(userId: userId, city: result) }
            Haptics.success()
        } label: {
            HStack(spacing: AppTheme.spacingSM) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text([result.state, result.country].compactMap { $0 }.joined(separator: ", "))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer(minLength: 0)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(AppTheme.cardDark)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
