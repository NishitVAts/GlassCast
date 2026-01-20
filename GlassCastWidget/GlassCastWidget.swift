//
//  GlassCastWidget.swift
//  GlassCastWidget
//
//  Created by Nishit Vats on 20/01/26.
//

import WidgetKit
import SwiftUI

private let widgetAppGroupId = "group.com.nishit.GlassCast"
private let widgetCacheKey = "glasscast.widget.cache.v1"

struct WidgetWeatherCache: Codable {
    let cityName: String
    let temperatureText: String
    let conditionText: String
    let icon: String
    let updatedAt: TimeInterval
}

private enum WidgetTheme {
    static func background(for condition: String) -> Color {
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

    static func foreground(for condition: String) -> Color {
        let key = condition.lowercased()
        if key.contains("rain") || key.contains("drizzle") || key.contains("thunder") {
            return .white
        }
        return .black
    }
}

private enum WidgetIconMapper {
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
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), cache: .placeholder)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, cache: loadCache())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration, cache: loadCache())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadCache() -> WidgetWeatherCache? {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupId) else { return nil }
        guard let data = defaults.data(forKey: widgetCacheKey) else { return nil }
        return try? JSONDecoder().decode(WidgetWeatherCache.self, from: data)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let cache: WidgetWeatherCache?
}

private extension WidgetWeatherCache {
    static var placeholder: WidgetWeatherCache {
        WidgetWeatherCache(
            cityName: "Patna",
            temperatureText: "26°",
            conditionText: "Clear",
            icon: "01d",
            updatedAt: Date().timeIntervalSince1970
        )
    }
}

struct GlassCastWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        let cache = entry.cache
        let city = cache?.cityName ?? "GlassCast"
        let temp = cache?.temperatureText ?? "—"
        let condition = cache?.conditionText ?? "Select a city"
        let icon = WidgetIconMapper.sfSymbol(for: cache?.icon ?? "")
        let bg = WidgetTheme.background(for: condition)
        let fg = WidgetTheme.foreground(for: condition)
        let updated = cache.map { Date(timeIntervalSince1970: $0.updatedAt) }

        Group {
            if let cache {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(cache.cityName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(fg)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(fg)
                    }

                    Text(cache.temperatureText)
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .foregroundStyle(fg)
                        .lineLimit(1)

                    Text(cache.conditionText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.85))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack {
                        Text("Updated \(Date(timeIntervalSince1970: cache.updatedAt).formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.black.opacity(0.9))
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                .padding(14)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(city)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "cloud.sun")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.black)
                    }

                    Text("Select a city")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Text("Open the app to choose a location and see live weather.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.7))
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Open app")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.92))
                        .clipShape(Capsule())

                        Spacer()
                    }
                }
                .padding(14)
            }
        }
        .containerBackground(bg, for: .widget)
        .widgetURL(URL(string: "glasscast://home"))
    }
}

struct GlassCastWidget: Widget {
    let kind: String = "GlassCastWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GlassCastWidgetEntryView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    GlassCastWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), cache: .placeholder)
}
