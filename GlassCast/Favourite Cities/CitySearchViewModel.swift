import Foundation

@MainActor
final class CitySearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [GeocodingResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let weatherClient: OpenWeatherClient

    init(weatherClient: OpenWeatherClient = OpenWeatherClient()) {
        self.weatherClient = weatherClient
    }

    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else {
            results = []
            return
        }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            results = try await weatherClient.geocodeCity(q)
        } catch {
            errorMessage = String(describing: error)
            results = []
        }
    }
}
