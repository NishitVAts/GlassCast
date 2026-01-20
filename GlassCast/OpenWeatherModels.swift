import Foundation

struct OpenWeatherCurrentResponse: Codable {
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    struct Main: Codable {
        let temp: Double
        let temp_min: Double
        let temp_max: Double
        let humidity: Double?
    }

    struct Wind: Codable {
        let speed: Double?
    }

    let name: String
    let weather: [Weather]
    let main: Main
    let wind: Wind?
    let visibility: Double?
}

struct OpenWeatherForecastResponse: Codable {
    struct Item: Codable {
        struct Main: Codable {
            let temp: Double
        }

        struct Weather: Codable {
            let id: Int
            let main: String
            let description: String
            let icon: String
        }

        let dt: TimeInterval
        let main: Main
        let weather: [Weather]
    }

    let list: [Item]
}

struct DailyForecast: Identifiable, Equatable {
    let id: Date
    let date: Date
    let minTemp: Double
    let maxTemp: Double
    let icon: String
    let summary: String
}
