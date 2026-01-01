//
//  Widgets.swift
//  Widgets
//
//  Created by Jack Kroll on 1/1/26.
//

import WidgetKit
import SwiftUI

struct StreakWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), currentStreak: 5, lastStudyDate: .now)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> StreakEntry {
        let currentStreak = UserDefaults.standard.value(forKey: "currentStreak") as? Int ?? 0
        let lastStudyDate = UserDefaults.standard.value(forKey: "lastStudyDate") as? Date ?? .distantPast
        return StreakEntry(date: Date(), currentStreak: currentStreak, lastStudyDate: lastStudyDate)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<StreakEntry> {
        var entries: [StreakEntry] = []
        
        let currentStreak = UserDefaults.standard.value(forKey: "currentStreak") as? Int ?? 0
        let lastStudyDate = UserDefaults.standard.value(forKey: "lastStudyDate") as? Date ?? .distantPast
        let calendar = Calendar.current
        
        let isActive = calendar.isDate(.now, inSameDayAs: lastStudyDate)
        let isSaveable = calendar.isDate(.now, inSameDayAs: calendar.date(byAdding: .day,value: 1,to: lastStudyDate) ?? .distantFuture)
        
        // Current streak (live)
        entries.append(StreakEntry(date: .now, currentStreak: currentStreak, lastStudyDate: lastStudyDate))
        
        if isActive && isSaveable{
            entries.append(StreakEntry(date: .now.addingTimeInterval(60*60*24), currentStreak: currentStreak, lastStudyDate: lastStudyDate))
        }
        
        // If can have another widget state
        if isActive || isSaveable{
            entries.append(StreakEntry(date: .now.addingTimeInterval(60*60*24), currentStreak: currentStreak, lastStudyDate: lastStudyDate))
        }
        
        
        

        return Timeline(entries: entries, policy: .never)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let lastStudyDate: Date
}

struct StreakViewWidget : View {
    let calendar = Calendar.current
    var entry: StreakWidgetProvider.Entry

    var body: some View {
        let currentStreak = entry.currentStreak
        let isActive = calendar.isDate(entry.date, inSameDayAs: entry.lastStudyDate)
        let isSaveable = calendar.isDate(entry.date, inSameDayAs: calendar.date(byAdding: .day,value: 1,to: entry.lastStudyDate) ?? .distantFuture)
        VStack {
            HStack {
                Image(systemName: isActive ? "flame.fill" : "flame")
                    .resizable()
                    .scaledToFit()
                if isActive || isSaveable {
                    Text(currentStreak.description)
                        .font(.system(size: 75))
                        .minimumScaleFactor(0.001)
                        .fontWeight(.heavy)
                        .fontDesign(.monospaced)
                }
            }
            .frame(maxHeight: 75)
            .foregroundStyle(isActive ? .orange : .gray)
            Text(isActive ? "STREAK ACTIVE" : isSaveable ? "STREAK AT RISK" : "STREAK LOST")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
                .fontDesign(.monospaced)
        }
    }
}

struct StreakWidgets: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: StreakWidgetProvider()) { entry in
            StreakViewWidget(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
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
    StreakWidgets()
} timeline: {
    StreakEntry(date: .now, currentStreak: 5, lastStudyDate: .now)
    StreakEntry(date: .now, currentStreak: 5, lastStudyDate: .now.addingTimeInterval(-22*60*60))
    StreakEntry(date: .now, currentStreak: 5, lastStudyDate: .now.addingTimeInterval(-48*60*60))
}

