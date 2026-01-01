//
//  StatsView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var entitlement: EntitlementManager
    @State var window: Int = 10
    let viewingSet: StudySet

    var body: some View {
        VStack {
        ScrollView {
            Group {
                //VStack(alignment: .leading, spacing: 16) {
                // Overview
                let avgCardDataPoint = viewingSet.cards.flatMap({ $0.stats.recordedStats }).count / viewingSet.cards.count
                if avgCardDataPoint <= 3 {
                    InfoCard(title: "Few Data Points Logged") {
                        Text("You have only tracked \(avgCardDataPoint) sessions on average per card. **Insight quality may be degraded**, practicing more will improve quality")
                    }
                }
                OverviewStatsCard(viewingSet: viewingSet, window: $window)
                    
                
                // Progress over windows (Accuracy vs Time)
                SetProgressCard(viewingSet: viewingSet, window: $window)
                
                // Per-card difficulty scatter
                CardDifficultyScatterCard(viewingSet: viewingSet, window: window)
                
                // Cards to consider retiring
                RetireCandidatesCard(viewingSet: viewingSet)
                
                // Cards to practice
                StrugglingCardsCard(viewingSet: viewingSet)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            }
            //.padding(.vertical, 12)
        }
        //.disabled(!entitlement.hasPro)
        //.redacted(reason: !entitlement.hasPro ? .placeholder : [])
        .navigationTitle("Stats")
    }
}

// MARK: - Overview Card

private struct OverviewStatsCard: View {
    let viewingSet: StudySet
    @Binding var window: Int

    private func averageAccuracy(window: Int) -> Double? {
        let values = viewingSet.cards.map { $0.stats.rollingPercentCorrect(recallWindow: window) * 100 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func averageTime(window: Int) -> TimeInterval? {
        let values = viewingSet.cards.map { $0.stats.avgTimeToFlip(recallWindow: window) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var totalReviews: Int {
        viewingSet.cards.reduce(0) { $0 + $1.stats.recordedStats.count }
    }

    private var totalFlags: Int {
        viewingSet.cards.reduce(0) { $0 + $1.stats.flags.count }
    }

    var body: some View {
        InfoCard(title: "Overview", subtitle: "A quick look at your recent performance") {
            if viewingSet.cards.flatMap({ $0.stats.recordedStats }).isEmpty {
                
                ContentUnavailableView {
                    Label("No Tracked Sessions", systemImage: "tray")
                } description: {
                    Text("Complete a study session to track your progress, your results will appear here")
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    // Latest window snapshot
                    if let acc = averageAccuracy(window: window), let time = averageTime(window: window) {
                        HStack(spacing: 16) {
                            MetricPill(title: "Accuracy", value: String(format: "%.0f%%", acc), systemImage: "checkmark.seal.fill", tint: .green)
                            MetricPill(title: "Avg Time", value: String(format: "%.1fs", time), systemImage: "timer", tint: .blue)
                        }
                    }

                    // Totals
                    HStack(spacing: 16) {
                        MetricPill(title: "Cards", value: "\(viewingSet.cards.count)", systemImage: "rectangle.on.rectangle.angled", tint: .teal)
                        MetricPill(title: "Reviews", value: "\(totalReviews)", systemImage: "chart.bar.doc.horizontal", tint: .indigo)
                        if totalFlags > 0 {
                            MetricPill(title: "Flags", value: "\(totalFlags)", systemImage: "flag.fill", tint: .orange)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Metric Pill

private struct MetricPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 25)
                .foregroundStyle(tint)
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
       
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .glassEffect()
        //.background(.thinMaterial, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    let studySet: StudySet = {
        let s = StudySet()
        for i in 1...20 {
            let card = Card(front: "Front #\(i)", back: "Back #\(i)")
            for _ in 1...3 {
                card.stats.record(timeToFlip: .random(in: 2...20), gotCorrect: Bool.random())
            }
            s.cards.append(card)
        }
        return s
    }()
    return NavigationStack { StatsView(viewingSet: studySet).environmentObject(EntitlementManager()) }
}
