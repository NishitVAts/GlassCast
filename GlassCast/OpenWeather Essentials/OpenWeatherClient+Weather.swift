import Foundation

extension OpenWeatherClient {
    func currentWeather(lat: Double, lon: Double, units: Units) async throws -> OpenWeatherCurrentResponse {
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        components.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "units", value: units.rawValue),
            .init(name: "appid", value: apiKey)
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(OpenWeatherCurrentResponse.self, from: data)
    }

    func forecast5Day(lat: Double, lon: Double, units: Units) async throws -> OpenWeatherForecastResponse {
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")!
        components.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "units", value: units.rawValue),
            .init(name: "appid", value: apiKey)
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: data)
    }
}
