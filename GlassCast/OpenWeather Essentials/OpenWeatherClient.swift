import Foundation

struct OpenWeatherClient {
    enum Units: String {
        case metric
        case imperial
    }

    let apiKey: String
    let session: URLSession

    init(apiKey: String = AppConfig.openWeatherAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func geocodeCity(_ query: String, limit: Int = 10) async throws -> [GeocodingResult] {
        var components = URLComponents(string: "https://api.openweathermap.org/geo/1.0/direct")!
        components.queryItems = [
            .init(name: "q", value: query),
            .init(name: "limit", value: String(limit)),
            .init(name: "appid", value: apiKey)
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response: response, data: data)
        return try JSONDecoder().decode([GeocodingResult].self, from: data)
    }

    func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

struct GeocodingResult: Codable, Identifiable {
    var id: String { "\(name)-\(lat)-\(lon)" }

    let name: String
    let lat: Double
    let lon: Double
    let country: String?
    let state: String?
}
