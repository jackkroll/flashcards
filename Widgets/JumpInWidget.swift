//
//  Widgets.swift
//  Widgets
//
//  Created by Jack Kroll on 1/1/26.
//

import WidgetKit
import SwiftUI
import SwiftData

struct JumpInWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> JumpInEntry {
        JumpInEntry(date: Date())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> JumpInEntry {
        JumpInEntry(date: Date())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<JumpInEntry> {
        var entries: [JumpInEntry] = []
        let calendar = Calendar.current
        for amount in 1...7 {
            entries.append(JumpInEntry(date: calendar.date(byAdding: .day, value: amount, to: .now) ?? .now))
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct JumpInEntry: TimelineEntry {
    let date: Date
    //let setToStudy: PersistentIdentifier
}

struct JumpInWidget : View {
    let entitlement = EntitlementManager()
    @Query private var sets: [StudySet]
    let calendar = Calendar.current
    var entry: JumpInWidgetProvider.Entry

    var body: some View {
        let set : StudySet? = sets.randomElement()
        VStack {
            if let set = set {
                Text(set.title.uppercased())
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(3)
                    .minimumScaleFactor(0.5)
                HStack {
                    Image(systemName: "rectangle.fill.on.rectangle.angled.fill")
                    Text("\((set.cards.count).formatted(.number)) CARDS")
                        .font(.caption)
                }
                HStack {
                    Image(systemName: "clock.fill")
                    Text(set.lastStudied?.formatted(date: .abbreviated, time: .omitted) ?? "Never Studied")
                }
                
                .widgetURL(.init(string: "recallapp://open-set?setTitle=\(set.title)"))
            }
            else {
                Text("create a study set with recall")
            }
        }
        
        .font(.caption)
        .foregroundStyle(.secondary)
        .fontWeight(.semibold)
        .fontDesign(.monospaced)
    }
}

struct JumpInWidgets: Widget {
    let kind: String = "JumpInWidget"
    
    var body: some WidgetConfiguration {
        let sharedModelContainer: ModelContainer = {
            let schema = Schema([
                StudySet.self, Card.self, SingleSide.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier("group.JackKroll.recall"))

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()

        return AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: JumpInWidgetProvider()) { entry in
            JumpInWidget(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(sharedModelContainer)
        }
    }
}
/*
extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}
*/
#Preview(as: .systemSmall) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StudySet.self, configurations: config)

    let set: StudySet = {
        let s = StudySet()
        s.title = "Study Set Title"
        for num in 1...20 {
            s.cards.append(Card(front: "Hello \(num.formatted(.number))", back: "World"))
        }
        s.lastStudied = .distantPast
        return s
    }()
    container.mainContext.insert(set)
    return JumpInWidgets()
} timeline: {
    JumpInEntry(date: .now)
}

