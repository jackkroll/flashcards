//
//  SetProgressCard.swift
//  flashcards
//
//  Shows accuracy and average time to flip across multiple recent windows.
//

import SwiftUI
import Charts

struct SetProgressCard: View {
    let viewingSet: StudySet
    @Binding var window : Int

    private struct SeriesPoint: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double // 0...1
        let series: String   // e.g., "Card #1" or "Aggregate"
        let isAggregate: Bool
    }

    private var perCardSeries: [SeriesPoint] {
        let calendar = Calendar.current
        var points: [SeriesPoint] = []
        for (idx, card) in viewingSet.cards.enumerated() {
            let grouped = Dictionary(grouping: card.stats.recordedStats) { review in
                calendar.startOfDay(for: review.timeCompleted)
            }
            for (day, reviews) in grouped {
                guard !reviews.isEmpty else { continue }
                let correct = reviews.reduce(0) { $0 + ($1.gotCorrect ? 1 : 0) }
                let acc = Double(correct) / Double(reviews.count)
                points.append(SeriesPoint(date: day, accuracy: acc, series: "Card #\(idx + 1)", isAggregate: false))
            }
        }
        return points.sorted { $0.date < $1.date }
    }

    private var aggregateSeries: [SeriesPoint] {
        let calendar = Calendar.current
        // Build a day -> [per-card accuracy] dictionary using perCardSeries
        var dayToAccuracies: [Date: [Double]] = [:]
        for p in perCardSeries {
            let day = calendar.startOfDay(for: p.date)
            if !p.isAggregate {
                dayToAccuracies[day, default: []].append(p.accuracy)
            }
        }
        // Average the per-card accuracies for each day
        let points = dayToAccuracies.map { (day, accs) in
            SeriesPoint(date: day,
                        accuracy: accs.reduce(0, +) / Double(accs.count),
                        series: "Aggregate",
                        isAggregate: true)
        }
        return points.sorted { $0.date < $1.date }
    }

    var body: some View {
        InfoCard(title: "Set Progress", subtitle: "Accuracy over time") {
            if viewingSet.cards.flatMap({ $0.stats.recordedStats }).isEmpty {
                ContentUnavailableView {
                    Label("No Data", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("Start reviewing to see your progress.")
                }
            } else {
                Chart {
                    ForEach(perCardSeries) { p in
                        LineMark(
                            x: .value("Date", p.date),
                            y: .value("Accuracy (%)", p.accuracy * 100),
                            series: .value("Card", p.series)
                        )
                        .foregroundStyle(.green)
                        .opacity(0.1)
                    }
                    ForEach(aggregateSeries) { p in
                        LineMark(
                            x: .value("Date", p.date),
                            y: .value("Accuracy (%)", p.accuracy * 100)
                        )
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        PointMark(
                            x: .value("Date", p.date),
                            y: .value("Accuracy (%)", p.accuracy * 100)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 220)
            }
        }
    }
}

#Preview {
    @Previewable @State var window = 10
    let studySet: StudySet = {
        let s = StudySet()
        let calendar = Calendar.current
        let now = Date()
        // Create 10 cards
        for i in 1...10 {
            let c = Card(front: "Card #\(i)", back: "B")
            // For each of the last 7 days, create a handful of reviews at varied times
            for dayOffset in 0..<7 {
                // 2–6 reviews per day
                let reviewsCount = Int.random(in: 2...6)
                for _ in 0..<reviewsCount {
                    // Random hour and minute within the day
                    let hour = Int.random(in: 8...22)
                    let minute = Int.random(in: 0...59)
                    var components = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: -dayOffset, to: now)!)
                    components.hour = hour
                    components.minute = minute
                    let reviewDate = calendar.date(from: components) ?? now

                    // Record a stat, then override the timeCompleted to our chosen date
                    let timeToFlip = TimeInterval.random(in: 2...12)
                    let correct = Bool.random()
                    c.stats.record(timeToFlip: timeToFlip, gotCorrect: correct)
                    if let last = c.stats.recordedStats.last {
                        last.timeCompleted = reviewDate
                    }
                }
            }
            s.cards.append(c)
        }
        return s
    }()
    return SetProgressCard(viewingSet: studySet, window: $window)
}
