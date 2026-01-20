import SwiftUI

enum WeatherIconMapper {
    static func sfSymbol(for openWeatherIcon: String) -> String {
        switch openWeatherIcon {
        case "01d": return "sun.max"
        case "01n": return "moon.stars"
        case "02d": return "cloud.sun"
        case "02n": return "cloud.moon"
        case "03d", "03n": return "cloud"
        case "04d", "04n": return "smoke"
        case "09d", "09n": return "cloud.drizzle"
        case "10d": return "cloud.sun.rain"
        case "10n": return "cloud.moon.rain"
        case "11d", "11n": return "cloud.bolt.rain"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog"
        default: return "cloud"
        }
    }

    static func themeBackground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("sun") || key.contains("clear") {
            return Color(red: 1.0, green: 0.88, blue: 0.16)
        }
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return Color(red: 0.20, green: 0.48, blue: 1.0)
        }
        if key.contains("snow") {
            return Color(red: 0.78, green: 0.92, blue: 1.0)
        }
        if key.contains("cloud") || key.contains("mist") || key.contains("fog") || key.contains("haze") {
            return Color(red: 0.82, green: 0.84, blue: 0.88)
        }
        return Color(red: 1.0, green: 0.88, blue: 0.16)
    }

    static func themeForeground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return .white
        }
        return .black
    }
}
