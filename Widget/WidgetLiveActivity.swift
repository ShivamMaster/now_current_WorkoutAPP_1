import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emoji: String
    }

    var name: String
}

struct WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetAttributes.self) { context in
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
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

extension WidgetAttributes {
    fileprivate static var preview: WidgetAttributes {
        WidgetAttributes(name: "World")
    }
}

extension WidgetAttributes.ContentState {
    fileprivate static var smiley: WidgetAttributes.ContentState {
        WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WidgetAttributes.ContentState {
         WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WidgetAttributes.preview) {
   WidgetLiveActivity()
} contentStates: {
    WidgetAttributes.ContentState.smiley
    WidgetAttributes.ContentState.starEyes
}
