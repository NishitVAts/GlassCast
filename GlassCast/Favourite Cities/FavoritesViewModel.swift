import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var favorites: [FavoriteCity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: FavoriteCitiesService

    init(service: FavoriteCitiesService = FavoriteCitiesService()) {
        self.service = service
    }

    func load(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            favorites = try await service.listFavorites(userId: userId)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func add(userId: UUID, city: GeocodingResult) async {
        do {
            let name = [city.name, city.state, city.country].compactMap { $0 }.joined(separator: ", ")
            try await service.addFavorite(userId: userId, cityName: name, lat: city.lat, lon: city.lon)
            await load(userId: userId)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func delete(at offsets: IndexSet, userId: UUID) async {
        let ids = offsets.compactMap { favorites[safe: $0]?.id }
        do {
            for id in ids {
                try await service.deleteFavorite(id: id)
            }
            await load(userId: userId)
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
