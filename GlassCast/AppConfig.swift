import Foundation

enum AppConfig {
    static var supabaseURL: URL {
        if let value = ProcessInfo.processInfo.environment["SUPABASE_URL"], let url = URL(string: value) {
            return url
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, let url = URL(string: value) {
            return url
        }
        preconditionFailure("Missing SUPABASE_URL")
    }

    static var supabaseAnonKey: String {
        if let value = ProcessInfo.processInfo.environment["SUPABASE_KEY"], !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String, !value.isEmpty {
            return value
        }
        preconditionFailure("Missing SUPABASE_KEY")
    }

    static var openWeatherAPIKey: String {
        if let value = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"], !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String, !value.isEmpty {
            return value
        }
        preconditionFailure("Missing OPENWEATHER_API_KEY")
    }
}
