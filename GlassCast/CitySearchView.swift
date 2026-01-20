import SwiftUI

struct CitySearchView: View {
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var sessionStore: SessionStore
    @Binding var selectedCityIdRawValue: String

    let onMenuTap: () -> Void

    @StateObject private var searchViewModel = CitySearchViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let bg = WeatherIconMapper.themeBackground(for: "clear")
        let fg = WeatherIconMapper.themeForeground(for: "clear")

        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(foreground: fg)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        searchField

                        if let message = favoritesViewModel.errorMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(Color.black.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        favoritesSection

                        resultsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
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
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
            }

            Spacer(minLength: 0)

            Text("Search")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(foreground)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            TextField("Search city", text: $searchViewModel.query)
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
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorites")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)

            if favoritesViewModel.favorites.isEmpty {
                Text("No favorites yet")
                    .font(.footnote)
                    .foregroundStyle(.black.opacity(0.6))
            } else {
                VStack(spacing: 10) {
                    ForEach(favoritesViewModel.favorites) { city in
                        favoriteRow(city: city)
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                Spacer()
                if searchViewModel.isSearching {
                    ProgressView()
                        .tint(.black)
                }
            }

            if let message = searchViewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if searchViewModel.results.isEmpty {
                if !searchViewModel.query.isEmpty {
                    Text("No results")
                        .font(.footnote)
                        .foregroundStyle(.black.opacity(0.6))
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(searchViewModel.results) { result in
                        resultRow(result: result)
                    }
                }
            }
        }
    }

    private func favoriteRow(city: FavoriteCity) -> some View {
        let isSelected = selectedCityIdRawValue == city.id.uuidString

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(city.city_name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(city.lat), \(city.lon)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.16))
            }

            Button {
                guard let userId = sessionStore.userId else { return }
                guard let idx = favoritesViewModel.favorites.firstIndex(where: { $0.id == city.id }) else { return }
                Task { await favoritesViewModel.delete(at: IndexSet(integer: idx), userId: userId) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            selectedCityIdRawValue = city.id.uuidString
        }
    }

    private func resultRow(result: GeocodingResult) -> some View {
        Button {
            guard let userId = sessionStore.userId else { return }
            Task {
                await favoritesViewModel.add(userId: userId, city: result)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text([result.name, result.state, result.country].compactMap { $0 }.joined(separator: ", "))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(result.lat), \(result.lon)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer(minLength: 0)

                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.16))
                    .frame(width: 36, height: 36)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
