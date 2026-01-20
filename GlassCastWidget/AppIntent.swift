//
//  AppIntent.swift
//  GlassCastWidget
//
//  Created by Nishit Vats on 20/01/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "GlassCast Widget"
    static var description = IntentDescription("Shows the latest weather for your selected city.")
}
