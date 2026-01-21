import SwiftUI
import UIKit

// MARK: - Design System

enum AppTheme {
    // Primary accent colors
    static let accent = Color(red: 1.0, green: 0.78, blue: 0.0) // Warm gold
    static let accentSecondary = Color(red: 0.98, green: 0.42, blue: 0.35) // Coral
    
    // Neutrals
    static let cardDark = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let cardLight = Color.white
    static let textPrimary = Color.black
    static let textSecondary = Color.black.opacity(0.6)
    static let textOnDark = Color.white
    static let textOnDarkSecondary = Color.white.opacity(0.7)
    
    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    
    // Corner radii
    static let radiusSM: CGFloat = 12
    static let radiusMD: CGFloat = 18
    static let radiusLG: CGFloat = 24
    static let radiusXL: CGFloat = 32
    
    // Shadows
    static func cardShadow() -> some View {
        Color.black.opacity(0.08)
    }
}

enum WeatherIconMapper {
    static func sfSymbol(for openWeatherIcon: String) -> String {
        switch openWeatherIcon {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }

    static func themeBackground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("sun") || key.contains("clear") {
            return Color(red: 1.0, green: 0.85, blue: 0.12) // Vibrant sunny yellow
        }
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return Color(red: 0.28, green: 0.52, blue: 0.96) // Rich blue
        }
        if key.contains("snow") {
            return Color(red: 0.85, green: 0.94, blue: 1.0) // Soft ice blue
        }
        if key.contains("cloud") || key.contains("mist") || key.contains("fog") || key.contains("haze") {
            return Color(red: 0.88, green: 0.90, blue: 0.94) // Soft gray
        }
        return Color(red: 1.0, green: 0.85, blue: 0.12)
    }
    
    static func themeGradient(for condition: String) -> LinearGradient {
        let key = condition.lowercased()
        if key.contains("sun") || key.contains("clear") {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.92, blue: 0.4), Color(red: 1.0, green: 0.78, blue: 0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.58, blue: 0.98), Color(red: 0.18, green: 0.38, blue: 0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        if key.contains("snow") {
            return LinearGradient(
                colors: [Color(red: 0.92, green: 0.96, blue: 1.0), Color(red: 0.78, green: 0.88, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        if key.contains("cloud") || key.contains("mist") || key.contains("fog") || key.contains("haze") {
            return LinearGradient(
                colors: [Color(red: 0.94, green: 0.95, blue: 0.97), Color(red: 0.82, green: 0.85, blue: 0.90)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(red: 1.0, green: 0.92, blue: 0.4), Color(red: 1.0, green: 0.78, blue: 0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func themeForeground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return .white
        }
        return .black
    }
}

// MARK: - Reusable Card Styles

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppTheme.spacingMD
    
    init(padding: CGFloat = AppTheme.spacingMD, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            }
    }
}

struct DarkCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppTheme.spacingMD
    
    init(padding: CGFloat = AppTheme.spacingMD, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(AppTheme.cardDark)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous))
    }
}

struct PillBadge: View {
    let text: String
    var style: Style = .dark
    
    enum Style {
        case dark, light, accent
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
    
    private var foregroundColor: Color {
        switch style {
        case .dark: return .white
        case .light: return .black
        case .accent: return .black
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .dark: return AppTheme.cardDark
        case .light: return .white
        case .accent: return AppTheme.accent
        }
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
