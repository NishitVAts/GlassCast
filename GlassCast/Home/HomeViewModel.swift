import Foundation
import WidgetKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedCity: FavoriteCity?

    @Published private(set) var temperatureText: String = "—"
    @Published private(set) var conditionText: String = "—"
    @Published private(set) var iconCode: String = ""
    @Published private(set) var hiLoText: String = "—"
    @Published private(set) var forecast: [DailyForecast] = []

    @Published private(set) var windText: String = "—"
    @Published private(set) var humidityText: String = "—"
    @Published private(set) var visibilityText: String = "—"

    @Published private(set) var windNumberText: String = "0"
    @Published private(set) var windUnitText: String = ""
    @Published private(set) var humidityNumberText: String = "0"
    @Published private(set) var humidityUnitText: String = "%"
    @Published private(set) var visibilityNumberText: String = "0"
    @Published private(set) var visibilityUnitText: String = ""
    
    // Additional weather data
    @Published private(set) var feelsLikeText: String = "—"
    @Published private(set) var pressureText: String = "—"
    @Published private(set) var cloudinessText: String = "—"
    @Published private(set) var windDirectionText: String = "—"
    @Published private(set) var sunriseText: String = "—"
    @Published private(set) var sunsetText: String = "—"
    @Published private(set) var weatherDescription: String = "—"
    @Published private(set) var lastUpdatedText: String = "—"

    private let client: OpenWeatherClient

    private let widgetAppGroupId = "group.com.nishit.GlassCast"
    private let widgetCacheKey = "glasscast.widget.cache.v1"

    init(client: OpenWeatherClient = OpenWeatherClient()) {
        self.client = client
    }

    func refresh(unit: TemperatureUnit) async {
        guard let selectedCity else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let units: OpenWeatherClient.Units = (unit == .celsius) ? .metric : .imperial

            async let current = client.currentWeather(lat: selectedCity.lat, lon: selectedCity.lon, units: units)
            async let fiveDay = client.forecast5Day(lat: selectedCity.lat, lon: selectedCity.lon, units: units)

            let currentResponse = try await current
            let forecastResponse = try await fiveDay

            temperatureText = formatTemp(currentResponse.main.temp, unit: unit)
            conditionText = currentResponse.weather.first?.main ?? "—"
            iconCode = currentResponse.weather.first?.icon ?? ""
            let conditionIcon = iconCode

            let hi = formatTemp(currentResponse.main.temp_max, unit: unit)
            let lo = formatTemp(currentResponse.main.temp_min, unit: unit)
            hiLoText = "H: \(hi)  L: \(lo)"

            windText = formatWind(currentResponse.wind?.speed, unit: unit)
            humidityText = formatHumidity(currentResponse.main.humidity)
            visibilityText = formatVisibility(currentResponse.visibility, unit: unit)

            let windParts = formatWindParts(currentResponse.wind?.speed, unit: unit)
            windNumberText = windParts.number
            windUnitText = windParts.unit

            let humidityParts = formatHumidityParts(currentResponse.main.humidity)
            humidityNumberText = humidityParts.number
            humidityUnitText = humidityParts.unit

            let visibilityParts = formatVisibilityParts(currentResponse.visibility, unit: unit)
            visibilityNumberText = visibilityParts.number
            visibilityUnitText = visibilityParts.unit
            
            // Additional weather data
            feelsLikeText = formatTemp(currentResponse.main.feels_like ?? currentResponse.main.temp, unit: unit)
            pressureText = formatPressure(currentResponse.main.pressure)
            cloudinessText = formatCloudiness(currentResponse.clouds?.all)
            windDirectionText = formatWindDirection(currentResponse.wind?.deg)
            sunriseText = formatTime(currentResponse.sys?.sunrise)
            sunsetText = formatTime(currentResponse.sys?.sunset)
            weatherDescription = currentResponse.weather.first?.description.capitalized ?? "—"
            lastUpdatedText = formatTime(currentResponse.dt)

            forecast = buildDaily(from: forecastResponse)

            storeWidgetCache(
                cityName: selectedCity.city_name,
                temperatureText: temperatureText,
                conditionText: conditionText,
                icon: conditionIcon,
                updatedAt: Date()
            )
        } catch {
            if Task.isCancelled { return }
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            if error is CancellationError { return }
            errorMessage = String(describing: error)
        }
    }

    private func storeWidgetCache(
        cityName: String,
        temperatureText: String,
        conditionText: String,
        icon: String,
        updatedAt: Date
    ) {
        struct WidgetCache: Codable {
            let cityName: String
            let temperatureText: String
            let conditionText: String
            let icon: String
            let updatedAt: TimeInterval
        }

        guard let defaults = UserDefaults(suiteName: widgetAppGroupId) else { return }
        let cache = WidgetCache(
            cityName: cityName,
            temperatureText: temperatureText,
            conditionText: conditionText,
            icon: icon,
            updatedAt: updatedAt.timeIntervalSince1970
        )

        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: widgetCacheKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "GlassCastWidget")
    }

    private func formatTemp(_ value: Double, unit: TemperatureUnit) -> String {
        let rounded = Int(value.rounded())
        return "\(rounded)°"
    }

    private func formatWind(_ value: Double?, unit: TemperatureUnit) -> String {
        guard let value else { return "—" }
        if unit == .celsius {
            let kmh = value * 3.6
            return "\(Int(kmh.rounded())) km/h"
        } else {
            let mph = value * 2.236936
            return "\(Int(mph.rounded())) mph"
        }
    }

    private func formatWindParts(_ value: Double?, unit: TemperatureUnit) -> (number: String, unit: String) {
        guard let value else { return ("0", "") }
        if unit == .celsius {
            let kmh = Int((value * 3.6).rounded())
            return (String(kmh), "km/h")
        } else {
            let mph = Int((value * 2.236936).rounded())
            return (String(mph), "mph")
        }
    }

    private func formatHumidity(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))%"
    }

    private func formatHumidityParts(_ value: Double?) -> (number: String, unit: String) {
        guard let value else { return ("0", "%") }
        return (String(Int(value.rounded())), "%")
    }

    private func formatVisibility(_ value: Double?, unit: TemperatureUnit) -> String {
        guard let value else { return "—" }
        if unit == .celsius {
            let km = value / 1000.0
            return "\(String(format: "%.1f", km)) km"
        } else {
            let miles = value / 1609.344
            return "\(String(format: "%.1f", miles)) mi"
        }
    }

    private func formatVisibilityParts(_ value: Double?, unit: TemperatureUnit) -> (number: String, unit: String) {
        guard let value else { return ("0", "") }
        if unit == .celsius {
            let km = value / 1000.0
            return (String(format: "%.1f", km), "km")
        } else {
            let miles = value / 1609.344
            return (String(format: "%.1f", miles), "mi")
        }
    }
    
    private func formatPressure(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded())) hPa"
    }
    
    private func formatCloudiness(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)%"
    }
    
    private func formatWindDirection(_ degrees: Double?) -> String {
        guard let degrees else { return "—" }
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    private func formatTime(_ timestamp: TimeInterval?) -> String {
        guard let timestamp else { return "—" }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func buildDaily(from response: OpenWeatherForecastResponse) -> [DailyForecast] {
        var buckets: [Date: [OpenWeatherForecastResponse.Item]] = [:]
        let calendar = Calendar.current

        for item in response.list {
            let date = Date(timeIntervalSince1970: item.dt)
            let day = calendar.startOfDay(for: date)
            buckets[day, default: []].append(item)
        }

        let days = buckets.keys.sorted().prefix(5)
        return days.compactMap { day in
            guard let items = buckets[day], !items.isEmpty else { return nil }
            let temps = items.map { $0.main.temp }
            let min = temps.min() ?? 0
            let max = temps.max() ?? 0
            let midItem = items[items.count / 2]
            let icon = midItem.weather.first?.icon ?? ""
            let summary = midItem.weather.first?.main ?? ""
            return DailyForecast(id: day, date: day, minTemp: min, maxTemp: max, icon: icon, summary: summary)
        }
    }
}
