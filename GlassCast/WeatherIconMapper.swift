import SwiftUI
import UIKit

enum WeatherIconMapper {
    static func sfSymbol(for openWeatherIcon: String) -> String {
        switch openWeatherIcon {
        case "01d": return "sun.max"
        case "01n": return "moon.stars"
        case "02d": return "cloud.sun"
        case "02n": return "cloud.moon"
        case "03d", "03n": return "cloud"
        case "04d", "04n": return "smoke"
        case "09d", "09n": return "cloud.drizzle"
        case "10d": return "cloud.sun.rain"
        case "10n": return "cloud.moon.rain"
        case "11d", "11n": return "cloud.bolt.rain"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog"
        default: return "cloud"
        }
    }

    static func themeBackground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("sun") || key.contains("clear") {
            return Color(red: 1.0, green: 0.88, blue: 0.16)
        }
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return Color(red: 0.20, green: 0.48, blue: 1.0)
        }
        if key.contains("snow") {
            return Color(red: 0.78, green: 0.92, blue: 1.0)
        }
        if key.contains("cloud") || key.contains("mist") || key.contains("fog") || key.contains("haze") {
            return Color(red: 0.82, green: 0.84, blue: 0.88)
        }
        return Color(red: 1.0, green: 0.88, blue: 0.16)
    }

    static func themeForeground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return .white
        }
        return .black
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.7

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let w = proxy.size.width
                    let h = proxy.size.height

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: max(160, w * 0.6), height: h)
                    .rotationEffect(.degrees(18))
                    .offset(x: w * phase)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                }
            }
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    func shimmer(_ active: Bool) -> some View {
        if active {
            return AnyView(self.modifier(ShimmerModifier()))
        } else {
            return AnyView(self)
        }
    }
}

struct SkeletonBlock: View {
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.22))
    }
}

@MainActor
enum Haptics {
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    static func medium() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var opacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
