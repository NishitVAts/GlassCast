import SwiftUI

struct HomeView: View {
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var sessionStore: SessionStore
    @Binding var selectedCityIdRawValue: String

    let onMenuTap: () -> Void

    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureUnit.celsius.rawValue
    @ObservedObject var viewModel: HomeViewModel
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        let gradient = WeatherIconMapper.themeGradient(for: viewModel.conditionText)
        let fg = WeatherIconMapper.themeForeground(for: viewModel.conditionText)

        ZStack {
            gradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: viewModel.conditionText)

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.spacingLG) {
                    topBar(foreground: fg)
                        .padding(.top, AppTheme.spacingSM)

                    heroSection(foreground: fg)
                        .offset(y: min(0, scrollOffset * 0.15))
                        .opacity(1 - max(0, -scrollOffset / 200))

                    quickStatsRow(foreground: fg)
                    
                    statsSection

                    sunTimesSection(foreground: fg)
                    
                    detailsSection(foreground: fg)

                    forecastSection(foreground: fg)
                    
                    footerSection(foreground: fg)
                }
                .padding(.horizontal, AppTheme.spacingLG)
                .padding(.bottom, AppTheme.spacingXL)
            }
            .coordinateSpace(name: "homeScroll")
            .background(ScrollOffsetReader(offset: $scrollOffset))
            .refreshable {
                await refreshWeather()
            }

            errorToast
        }
        .task {
            await loadFavoritesIfNeeded()
            syncSelectionFromStorage()
            await refreshWeather()
        }
        .onChange(of: selectedCityIdRawValue) { _ in
            syncSelectionFromStorage()
            Task { await refreshWeather() }
        }
    }
    
    // MARK: - Hero Section
    
    private func heroSection(foreground: Color) -> some View {
        VStack(spacing: AppTheme.spacingMD) {
            VStack(spacing: AppTheme.spacingXS) {
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(viewModel.selectedCity?.city_name ?? "Select a city")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .foregroundStyle(foreground)

                if favoritesViewModel.favorites.isEmpty {
                    Text("Add your first city from the menu")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(foreground.opacity(0.7))
                } else if viewModel.selectedCity == nil {
                    Text("Tap the location icon to pick a city")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(foreground.opacity(0.7))
                }
            }

            PillBadge(text: Date().longDayMonth(), style: .dark)

            if viewModel.isLoading {
                SkeletonBlock(cornerRadius: 30)
                    .frame(width: 200, height: 130)
                    .shimmer(true)
            } else {
                VStack(spacing: AppTheme.spacingXS) {
                    HStack(alignment: .top, spacing: 4) {
                        Text(viewModel.temperatureText.replacingOccurrences(of: "°", with: ""))
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("°")
                            .font(.system(size: 48, weight: .medium, design: .rounded))
                            .offset(y: 16)
                    }
                    .foregroundStyle(foreground)
                    
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: WeatherIconMapper.sfSymbol(for: viewModel.iconCode))
                            .font(.system(size: 22, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text(viewModel.conditionText)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(foreground)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.temperatureText)
            }
            
            if !viewModel.hiLoText.isEmpty && !viewModel.isLoading {
                Text(viewModel.hiLoText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(foreground.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXL)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        Group {
            if viewModel.isLoading {
                SkeletonBlock(cornerRadius: AppTheme.radiusMD)
                    .frame(height: 100)
                    .shimmer(true)
            } else if viewModel.selectedCity != nil {
                HStack(spacing: 0) {
                    statItem(icon: "wind", value: viewModel.windNumberText, unit: viewModel.windUnitText, label: "Wind")
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 50)
                    
                    statItem(icon: "drop.fill", value: viewModel.humidityNumberText, unit: viewModel.humidityUnitText, label: "Humidity")
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 50)
                    
                    statItem(icon: "eye.fill", value: viewModel.visibilityNumberText, unit: viewModel.visibilityUnitText, label: "Visibility")
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardDark)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous))
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.windNumberText)
    }
    
    private func statItem(icon: String, value: String, unit: String, label: String) -> some View {
        VStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            HStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Forecast Section
    
    private func forecastSection(foreground: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            if !viewModel.forecast.isEmpty {
                HStack {
                    Text("This Week")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                    Text("\(viewModel.forecast.count) days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(foreground.opacity(0.6))
                }
                .foregroundStyle(foreground)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingSM) {
                        ForEach(viewModel.forecast) { day in
                            forecastCard(day: day, foreground: foreground)
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if viewModel.selectedCity != nil && viewModel.isLoading {
                HStack(spacing: AppTheme.spacingSM) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonBlock(cornerRadius: AppTheme.radiusSM)
                            .frame(width: 72, height: 100)
                    }
                }
                .shimmer(true)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.forecast.count)
    }
    
    private func forecastCard(day: DailyForecast, foreground: Color) -> some View {
        VStack(spacing: AppTheme.spacingSM) {
            Text(day.date.weekdayShort())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(foreground.opacity(0.7))
            
            Image(systemName: WeatherIconMapper.sfSymbol(for: day.icon))
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(foreground)
            
            Text("\(Int(day.maxTemp.rounded()))°")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)
        }
        .frame(width: 72)
        .padding(.vertical, AppTheme.spacingMD)
        .background(foreground.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                .strokeBorder(foreground.opacity(0.12), lineWidth: 1)
        }
    }
    
    // MARK: - Quick Stats Row (Feels Like)
    
    private func quickStatsRow(foreground: Color) -> some View {
        Group {
            if viewModel.selectedCity != nil && !viewModel.isLoading {
                HStack(spacing: AppTheme.spacingSM) {
                    // Feels Like
                    quickStatCard(
                        icon: "thermometer.sun.fill",
                        title: "Feels Like",
                        value: viewModel.feelsLikeText,
                        foreground: foreground
                    )
                    
                    // Cloudiness
                    quickStatCard(
                        icon: "cloud.fill",
                        title: "Cloudiness",
                        value: viewModel.cloudinessText,
                        foreground: foreground
                    )
                }
            }
        }
    }
    
    private func quickStatCard(icon: String, title: String, value: String, foreground: Color) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(foreground.opacity(0.8))
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(foreground.opacity(0.6))
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
            }
            
            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity)
        .background(foreground.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
    }
    
    // MARK: - Sun Times Section
    
    private func sunTimesSection(foreground: Color) -> some View {
        Group {
            if viewModel.selectedCity != nil && !viewModel.isLoading {
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    Text("Sun Schedule")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                    
                    HStack(spacing: AppTheme.spacingSM) {
                        sunTimeCard(
                            icon: "sunrise.fill",
                            title: "Sunrise",
                            time: viewModel.sunriseText,
                            foreground: foreground,
                            iconColor: Color.orange
                        )
                        
                        sunTimeCard(
                            icon: "sunset.fill",
                            title: "Sunset",
                            time: viewModel.sunsetText,
                            foreground: foreground,
                            iconColor: Color.pink
                        )
                    }
                }
            }
        }
    }
    
    private func sunTimeCard(icon: String, title: String, time: String, foreground: Color, iconColor: Color) -> some View {
        VStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(foreground.opacity(0.6))
            
            Text(time)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingMD)
        .background(foreground.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                .strokeBorder(foreground.opacity(0.1), lineWidth: 1)
        }
    }
    
    // MARK: - Details Section
    
    private func detailsSection(foreground: Color) -> some View {
        Group {
            if viewModel.selectedCity != nil && !viewModel.isLoading {
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    Text("Weather Details")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                    
                    VStack(spacing: 0) {
                        detailRow(icon: "gauge.medium", label: "Pressure", value: viewModel.pressureText, foreground: foreground)
                        
                        Divider().overlay(Color.white.opacity(0.1))
                        
                        detailRow(icon: "arrow.up.right.circle", label: "Wind Direction", value: viewModel.windDirectionText, foreground: foreground)
                        
                        Divider().overlay(Color.white.opacity(0.1))
                        
                        detailRow(icon: "text.quote", label: "Description", value: viewModel.weatherDescription, foreground: foreground)
                    }
                    .background(AppTheme.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous))
                }
            }
        }
    }
    
    private func detailRow(icon: String, label: String, value: String, foreground: Color) -> some View {
        HStack {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 24)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, AppTheme.spacingMD)
    }
    
    // MARK: - Footer Section
    
    private func footerSection(foreground: Color) -> some View {
        Group {
            if viewModel.selectedCity != nil && !viewModel.isLoading {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .medium))
                    Text("Updated \(viewModel.lastUpdatedText)")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(foreground.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.spacingSM)
            }
        }
    }
    
    // MARK: - Error Toast
    
    @ViewBuilder
    private var errorToast: some View {
        if let message = viewModel.errorMessage {
            VStack {
                Spacer()
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(red: 0.9, green: 0.3, blue: 0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                .padding(.bottom, AppTheme.spacingLG)
            }
            .allowsHitTesting(false)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var unit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
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

            Menu {
                ForEach(favoritesViewModel.favorites) { city in
                    Button {
                        selectedCityIdRawValue = city.id.uuidString
                        Haptics.light()
                    } label: {
                        Label(city.city_name, systemImage: "mappin.circle")
                    }
                }
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(foreground)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
            }
            .disabled(favoritesViewModel.favorites.isEmpty)
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
