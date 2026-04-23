import Foundation

struct OpenRouterClient {
    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    init(apiKey: String = AppConfig.openRouterAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func sendMessage(_ messages: [OpenRouterRequest.Message], model: String = "openai/gpt-3.5-turbo") async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://glasscast.app", forHTTPHeaderField: "HTTP-Referer") // Required by OpenRouter
        request.setValue("GlassCast iOS", forHTTPHeaderField: "X-Title")

        let body = OpenRouterRequest(model: model, messages: messages, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OpenRouter Error: \(errorMsg)")
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}
