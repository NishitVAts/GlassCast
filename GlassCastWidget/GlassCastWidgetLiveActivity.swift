//
//  GlassCastWidgetLiveActivity.swift
//  GlassCastWidget
//
//  Created by Nishit Vats on 20/01/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GlassCastWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GlassCastWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GlassCastWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension GlassCastWidgetAttributes {
    fileprivate static var preview: GlassCastWidgetAttributes {
        GlassCastWidgetAttributes(name: "World")
    }
}

extension GlassCastWidgetAttributes.ContentState {
    fileprivate static var smiley: GlassCastWidgetAttributes.ContentState {
        GlassCastWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GlassCastWidgetAttributes.ContentState {
         GlassCastWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GlassCastWidgetAttributes.preview) {
   GlassCastWidgetLiveActivity()
} contentStates: {
    GlassCastWidgetAttributes.ContentState.smiley
    GlassCastWidgetAttributes.ContentState.starEyes
}
