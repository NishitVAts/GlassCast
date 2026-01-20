import SwiftUI

struct HomeView: View {
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var sessionStore: SessionStore
    @Binding var selectedCityIdRawValue: String

    let onMenuTap: () -> Void

    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureUnit.celsius.rawValue
    @StateObject private var viewModel = HomeViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        let bg = WeatherIconMapper.themeBackground(for: viewModel.conditionText)
        let fg = WeatherIconMapper.themeForeground(for: viewModel.conditionText)

        ZStack {
            bg
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: viewModel.conditionText)

            ScrollView {
                VStack(spacing: 18) {
                    topBar(foreground: fg)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        VStack(spacing: 6) {
                            Text(viewModel.selectedCity?.city_name ?? "Select a city")
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .foregroundStyle(fg)

                            if favoritesViewModel.favorites.isEmpty {
                                Text("Add your first city from Search to see the forecast here.")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(fg.opacity(0.75))
                            } else if viewModel.selectedCity == nil {
                                Text("Tap the location icon to pick a favorite.")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(fg.opacity(0.75))
                            }
                        }

                        Text(Date().longDayMonth())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.black)
                            .clipShape(Capsule())

                        Text(viewModel.conditionText)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(fg)

                        Group {
                            if viewModel.isLoading {
                                SkeletonBlock(cornerRadius: 26)
                                    .frame(height: 120)
                                    .shimmer(true)
                            } else {
                                Text(viewModel.temperatureText)
                                    .font(.system(size: 110, weight: .semibold, design: .rounded))
                                    .foregroundStyle(fg)
                                    .lineLimit(1)
                                    .contentTransition(.numericText())
                                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.temperatureText)
                            }
                        }
                    }
                    .offset(y: scrollOffset * 0.12)
                    .animation(.easeOut(duration: 0.18), value: scrollOffset)

                    dailySummary(foreground: fg)

                    Group {
                        if viewModel.isLoading {
                            SkeletonBlock(cornerRadius: 18)
                                .frame(height: 92)
                                .shimmer(true)
                        } else {
                            statsCard
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.45, dampingFraction: 0.9), value: viewModel.windNumberText)
                        }
                    }

                    if !viewModel.forecast.isEmpty {
                        weeklyForecastHeader(foreground: fg)
                        weeklyForecastRow(foreground: fg)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: viewModel.forecast.count)
                    } else if viewModel.selectedCity != nil {
                        if viewModel.isLoading {
                            HStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonBlock(cornerRadius: 14)
                                        .frame(width: 76, height: 86)
                                }
                            }
                            .shimmer(true)
                        } else {
                            Text("Pull to refresh to load the latest weekly forecast.")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(fg.opacity(0.75))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: "homeScroll")
            .background(ScrollOffsetReader(offset: $scrollOffset))
            .refreshable {
                await refreshWeather()
            }

            if let message = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color.black.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, 18)
                }
                .allowsHitTesting(false)
            }
        }
        .task {
            await loadFavoritesIfNeeded()
            syncSelectionFromStorage()
            await refreshWeather()
        }
        .onChange(of: selectedCityIdRawValue) { _ in
            
            syncSelectionFromStorage()
            
            Task {
                await refreshWeather()
            }
        }
    }

    private var unit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }

    private func topBar(foreground: Color) -> some View {
        HStack {
            Button {
                onMenuTap()
                Task { @MainActor in Haptics.medium() }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer(minLength: 0)

            Menu {
                ForEach(favoritesViewModel.favorites) { city in
                    Button(city.city_name) {
                        selectedCityIdRawValue = city.id.uuidString
                        Task { @MainActor in Haptics.light() }
                    }
                }
            } label: {
                Image(systemName: "location.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
            }
            .disabled(favoritesViewModel.favorites.isEmpty)
        }
    }

    private func dailySummary(foreground: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Daily Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foreground)
            Text("\(viewModel.hiLoText)")
                .font(.footnote)
                .foregroundStyle(foreground.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
        .offset(y: scrollOffset * 0.08)
    }

    private var statsCard: some View {
        HStack(spacing: 12) {
            statItem(icon: "wind", number: viewModel.windNumberText, unit: viewModel.windUnitText, label: "Wind")
            statItem(icon: "drop", number: viewModel.humidityNumberText, unit: viewModel.humidityUnitText, label: "Humidity")
            statItem(icon: "eye", number: viewModel.visibilityNumberText, unit: viewModel.visibilityUnitText, label: "Visibility")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statItem(icon: String, number: String, unit: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.16))

            HStack(spacing: 4) {
                Text(number)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: number)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private func weeklyForecastHeader(foreground: Color) -> some View {
        HStack {
            Text("Weekly forecast")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foreground)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foreground)
        }
        .padding(.top, 6)
    }

    private func weeklyForecastRow(foreground: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.forecast) { day in
                    VStack(spacing: 8) {
                        Text("\(Int(day.maxTemp.rounded()))°")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                        Image(systemName: WeatherIconMapper.sfSymbol(for: day.icon))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.black)
                        Text(day.date.weekdayShort())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.7))
                    }
                    .padding(.vertical, 12)
                    .frame(width: 76)
                    .background(Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.18), lineWidth: 2)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func loadFavoritesIfNeeded() async {
        guard let userId = sessionStore.userId else { return }
        if favoritesViewModel.favorites.isEmpty {
            await favoritesViewModel.load(userId: userId)
        }
    }

    private func syncSelectionFromStorage() {
        if let selectedId = UUID(uuidString: selectedCityIdRawValue),
           let match = favoritesViewModel.favorites.first(where: { $0.id == selectedId }) {
            viewModel.selectedCity = match
            return
        }

        if let first = favoritesViewModel.favorites.first {
            selectedCityIdRawValue = first.id.uuidString
            viewModel.selectedCity = first
        } else {
            viewModel.selectedCity = nil
        }
    }

    private func refreshWeather() async {
        await viewModel.refresh(unit: unit)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ScrollOffsetReader: View {
    @Binding var offset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("homeScroll")).minY
                )
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            offset = value
        }
    }
}
