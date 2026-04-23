import SwiftUI
import Combine

@MainActor
class AIAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let client = OpenRouterClient()
    private var cancellables = Set<AnyCancellable>()
    private var weatherContext: String?
    
    private var systemPrompt: String {
        var prompt = """
        You are GlassCast AI, a specialist in skincare, sun protection, and health. 
        Your goal is to suggest skincare routines, advise on sun exposure based on UV levels, and answer health-related questions.
        Be professional, helpful, and concise. 
        Always remind users to consult with a professional dermatologist for medical concerns.
        """
        
        if let context = weatherContext {
            prompt += "\n\nCurrent Weather Context:\n\(context)"
            prompt += "\n\nPlease use this weather data to provide personalized skincare and sun protection advice automatically in your initial response."
        }
        
        return prompt
    }
    
    init() {
        // Initial welcome message will be updated once weather is provided
    }
    
    func updateWeatherContext(temperature: String, condition: String, humidity: String, uvIndex: String? = nil) {
        let context = "Temperature: \(temperature), Condition: \(condition), Humidity: \(humidity)\(uvIndex != nil ? ", UV Index: \(uvIndex!)" : "")."
        self.weatherContext = context
        
        // If it's the start of the conversation, trigger an automatic suggestion
        if messages.isEmpty {
            generateInitialSuggestion()
        }
    }
    
    private func generateInitialSuggestion() {
        isLoading = true
        
        Task {
            do {
                let apiMessages = [
                    OpenRouterRequest.Message(role: "system", content: systemPrompt),
                    OpenRouterRequest.Message(role: "user", content: "Based on the current weather, what skincare routine and sun protection do you recommend for me today?")
                ]
                
                let response = try await client.sendMessage(apiMessages)
                isLoading = false
                await animateResponse(response)
            } catch {
                isLoading = false
                messages.append(ChatMessage(role: .assistant, content: "Hello! I'm your GlassCast AI. Please check your connection so I can give you weather-based skincare tips!"))
            }
        }
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        
        Task {
            do {
                let apiMessages = [
                    OpenRouterRequest.Message(role: "system", content: systemPrompt)
                ] + messages.map { OpenRouterRequest.Message(role: $0.role == .user ? "user" : "assistant", content: $0.content) }
                
                let response = try await client.sendMessage(apiMessages)
                isLoading = false
                
                await animateResponse(response)
            } catch {
                isLoading = false
                let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I encountered an error. Please check your connection or try again later.")
                messages.append(errorMessage)
            }
        }
    }
    
    private func animateResponse(_ response: String) async {
        var assistantMessage = ChatMessage(role: .assistant, content: "", isAnimating: true)
        messages.append(assistantMessage)
        
        let messageIndex = messages.count - 1
        
        for char in response {
            messages[messageIndex].content.append(char)
            try? await Task.sleep(nanoseconds: 20_000_000) // 0.02 seconds delay
        }
        
        messages[messageIndex].isAnimating = false
    }
}
