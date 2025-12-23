//
//  RetireAndStruggleCards.swift
//  flashcards
//
//  Lists of cards recommended for retirement or extra practice based on heuristics.
//

import SwiftUI

struct RetireCandidatesCard: View {
    let viewingSet: StudySet
    let window: Int
    let minAccuracy: Double // 0...1
    let maxTime: TimeInterval

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let index: Int
    }

    private var items: [Item] {
        viewingSet.cards.enumerated()
            .filter { (_, card) in
                let acc = card.stats.rollingPercentCorrect(recallWindow: window)
                let time = card.stats.avgTimeToFlip(recallWindow: window)
                return acc >= minAccuracy && time <= maxTime
            }
            .map { (idx, card) in
                let acc = card.stats.rollingPercentCorrect(recallWindow: window)
                let time = card.stats.avgTimeToFlip(recallWindow: window)
                return Item(title: card.front.text ?? "",
                            subtitle: String(format: "%.0f%% · %.1fs", acc * 100, time),
                            index: idx)
            }
            .sorted { $0.index < $1.index }
    }

    var body: some View {
        InfoCard(title: "Consider Retiring", subtitle: "High accuracy, quick flips") {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("No Candidates", systemImage: "checkmark.circle")
                } description: {
                    Text("Keep practicing to build mastery.")
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items.prefix(5)) { item in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "archivebox")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("#\(item.index + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    if items.count > 5 {
                        NavigationLink {
                            
                        } label: {
                            Text("and \(items.count - 5) more")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct StrugglingCardsCard: View {
    let viewingSet: StudySet
    let window: Int
    let maxAccuracy: Double // 0...1
    let minTime: TimeInterval

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let index: Int
    }

    private var items: [Item] {
        viewingSet.cards.enumerated()
            .map { (idx, card) -> (idx: Int, title: String, acc: Double, time: TimeInterval) in
                let acc = card.stats.rollingPercentCorrect(recallWindow: window)
                let time = card.stats.avgTimeToFlip(recallWindow: window)
                return (idx: idx, title: card.front.text ?? "", acc: acc, time: time)
            }
            .filter { tuple in
                tuple.acc <= maxAccuracy || tuple.time >= minTime
            }
            .sorted { l, r in
                if l.acc != r.acc { return l.acc < r.acc }
                return l.time > r.time
            }
            .map { tuple in
                Item(title: tuple.title,
                     subtitle: String(format: "%.0f%% · %.1fs", tuple.acc * 100, tuple.time),
                     index: tuple.idx)
            }
    }

    var body: some View {
        InfoCard(title: "Needs Practice", subtitle: "Low accuracy or slow flips") {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Looking Good!", systemImage: "hand.thumbsup")
                } description: {
                    Text("No struggling cards right now.")
                }
                
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items.prefix(5)) { item in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("#\(item.index + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                    }
                    if items.count > 5 {
                        NavigationLink {
                            
                        } label: {
                            Text("and \(items.count - 5) more")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let studySet: StudySet = {
        let s = StudySet()
        for i in 1...15 {
            let c = Card(front: "Card #\(i)", back: "B")
            for _ in 0..<40 { c.stats.record(timeToFlip: .random(in: 2...12), gotCorrect: Bool.random()) }
            s.cards.append(c)
        }
        return s
    }()
    return VStack(spacing: 16) {
        ScrollView {
            RetireCandidatesCard(viewingSet: studySet, window: 25, minAccuracy: 0.4, maxTime: 9)
            StrugglingCardsCard(viewingSet: studySet, window: 25, maxAccuracy: 0.6, minTime: 8)
        }
    }
    .padding()
}
