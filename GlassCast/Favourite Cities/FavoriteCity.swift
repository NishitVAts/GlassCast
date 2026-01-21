import Foundation

struct FavoriteCity: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID
    let city_name: String
    let lat: Double
    let lon: Double
    let created_at: Date?
}

struct NewFavoriteCity: Codable {
    let user_id: UUID
    let city_name: String
    let lat: Double
    let lon: Double
}
