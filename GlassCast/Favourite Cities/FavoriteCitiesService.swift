import Foundation
import Supabase

struct FavoriteCitiesService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func listFavorites(userId: UUID) async throws -> [FavoriteCity] {
        try await client
            .from("favorite_cities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func addFavorite(userId: UUID, cityName: String, lat: Double, lon: Double) async throws {
        let new = NewFavoriteCity(user_id: userId, city_name: cityName, lat: lat, lon: lon)
        _ = try await client
            .from("favorite_cities")
            .insert(new)
            .execute()
    }

    func deleteFavorite(id: UUID) async throws {
        _ = try await client
            .from("favorite_cities")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
