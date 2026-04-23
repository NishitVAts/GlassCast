import Foundation

struct OpenRouterRequest: Codable {
    let model: String
    let messages: [Message]
    let stream: Bool?
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OpenRouterResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    var content: String
    var isAnimating: Bool = false
    
    enum MessageRole {
        case user
        case assistant
    }
}
