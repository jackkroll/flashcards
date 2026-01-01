//
//  RetireAndStruggleCards.swift
//  flashcards
//
//  Lists of cards recommended for retirement or extra practice based on heuristics.
//

import SwiftUI

struct RetireCandidatesCard: View {
    let viewingSet: StudySet

    @AppStorage("strongMinPercentCorrectEnabled") private var strongMinPercentCorrectEnabled: Bool = true
    @AppStorage("strongMinPercentCorrect") private var strongMinPercentCorrect: Double = 0.4
    @AppStorage("strongMaxTimeToFlipEnabled") private var strongMaxTimeToFlipEnabled: Bool = true
    @AppStorage("strongMaxTimeToFlipSeconds") private var strongMaxTimeToFlipSeconds: Double = 9
    @AppStorage("strongRecallWindow") private var strongRecallWindow: Int = 25

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let acc: Double
        let time: TimeInterval
        let index: Int
    }

    private var items: [Item] {
        viewingSet.cards.enumerated()
            .filter { (_, card) in
                card.determineIfStrong(
                    minPercentCorrect: strongMinPercentCorrectEnabled ? strongMinPercentCorrect : nil,
                    maxTimeToFlip: strongMaxTimeToFlipEnabled ? strongMaxTimeToFlipSeconds : nil,
                    recallWindow: strongRecallWindow
                )
            }
            .map { (idx, card) in
                let acc = card.stats.rollingPercentCorrect(recallWindow: strongRecallWindow)
                let time = card.stats.avgTimeToFlip(recallWindow: strongRecallWindow)
                return Item(title: card.front.text ?? "",
                            acc: acc,
                            time: time,
                            index: idx)
            }
            .sorted { $0.index < $1.index }
    }

    var body: some View {
        InfoCard(title: "Consider Retiring", subtitle: "High accuracy, quick solves") {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("No Candidates", systemImage: "checkmark.circle")
                } description: {
                    Text("Keep practicing to build mastery.")
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items.prefix(5)) { item in
                        VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.body)
                                    .lineLimit(1)
                                HStack{
                                    ProgressView(value: item.acc)
                                        .progressViewStyle(.linear)
                                        .tint(.green)
                                    Text(String(format: "%.0f%%", item.acc * 100))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                Text(String(format: "%.1fs avg", item.time))
                                    .font(.caption2)
                                    .padding(5)
                                    .glassEffect()
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    if items.count > 5 {
                        NavigationLink {
                            RetireCandidatesFullList(viewingSet: viewingSet)
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

    @AppStorage("weakMaxPercentCorrectEnabled") private var weakMaxPercentCorrectEnabled: Bool = true
    @AppStorage("weakMaxPercentCorrect") private var weakMaxPercentCorrect: Double = 0.6
    @AppStorage("weakMinTimeToFlipEnabled") private var weakMinTimeToFlipEnabled: Bool = true
    @AppStorage("weakMinTimeToFlipSeconds") private var weakMinTimeToFlipSeconds: Double = 8
    @AppStorage("weakRecallWindow") private var weakRecallWindow: Int = 25

    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let acc: Double
        let time: TimeInterval
        let index: Int
    }

    private var items: [Item] {
        viewingSet.cards.enumerated()
            .filter { (_, card) in
                card.determineIfWeak(
                    maxPercentCorrect: weakMaxPercentCorrectEnabled ? weakMaxPercentCorrect : nil,
                    minTimeToFlip: weakMinTimeToFlipEnabled ? weakMinTimeToFlipSeconds : nil,
                    recallWindow: weakRecallWindow
                )
            }
            .map { (idx, card) -> (idx: Int, title: String, acc: Double, time: TimeInterval) in
                let acc = card.stats.rollingPercentCorrect(recallWindow: weakRecallWindow)
                let time = card.stats.avgTimeToFlip(recallWindow: weakRecallWindow)
                return (idx: idx, title: card.front.text ?? "", acc: acc, time: time)
            }
            .sorted { l, r in
                if l.acc != r.acc { return l.acc < r.acc }
                return l.time > r.time
            }
            .map { tuple in
                Item(title: tuple.title,
                     acc: tuple.acc,
                     time: tuple.time,
                     index: tuple.idx)
            }
    }

    var body: some View {
        InfoCard(title: "Needs Practice", subtitle: "Low accuracy or slow solves") {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Looking Good!", systemImage: "hand.thumbsup")
                } description: {
                    Text("No struggling cards right now.")
                }
                
            } else {
                VStack(alignment: .leading, spacing: 8) {
                        ForEach(items.prefix(5)) { item in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.body)
                                        .lineLimit(1)
                                    HStack {
                                        ProgressView(value: item.acc)
                                            .progressViewStyle(.linear)
                                            .tint(.orange)
                                            .frame(maxWidth: .infinity)
                                        Text(String(format: "%.0f%%", item.acc * 100))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "%.1fs avg", item.time))
                                            .font(.caption2)
                                            .padding(5)
                                            .glassEffect()
                                    }
                            }
                            .padding(.vertical, 4)
                    }
                    if items.count > 5 {
                        NavigationLink {
                            StrugglingCardsFullList(viewingSet: viewingSet)
                        } label: {
                            Text("and \(items.count - 5) more")
                        }
                    }
                }
            }
        }
    }
}

struct RetireCandidatesFullList: View {
    let viewingSet: StudySet

    @AppStorage("strongMinPercentCorrectEnabled") private var strongMinPercentCorrectEnabled: Bool = true
    @AppStorage("strongMinPercentCorrect") private var strongMinPercentCorrect: Double = 0.4
    @AppStorage("strongMaxTimeToFlipEnabled") private var strongMaxTimeToFlipEnabled: Bool = true
    @AppStorage("strongMaxTimeToFlipSeconds") private var strongMaxTimeToFlipSeconds: Double = 9
    @AppStorage("strongRecallWindow") private var strongRecallWindow: Int = 25

    private struct RowItem: Identifiable {
        let id = UUID()
        let title: String
        let acc: Double
        let time: TimeInterval
    }

    private var items: [RowItem] {
        viewingSet.cards
            .filter { card in
                card.determineIfStrong(
                    minPercentCorrect: strongMinPercentCorrectEnabled ? strongMinPercentCorrect : nil,
                    maxTimeToFlip: strongMaxTimeToFlipEnabled ? strongMaxTimeToFlipSeconds : nil,
                    recallWindow: strongRecallWindow
                )
            }
            .map { card in
                let acc = card.stats.rollingPercentCorrect(recallWindow: strongRecallWindow)
                let time = card.stats.avgTimeToFlip(recallWindow: strongRecallWindow)
                return RowItem(title: card.front.text ?? "", acc: acc, time: time)
            }
    }

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        ProgressView(value: item.acc)
                            .progressViewStyle(.linear)
                            .tint(.green)
                        Text(String(format: "%.0f%%", item.acc * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1fs avg", item.time))
                            .font(.caption2)
                            .padding(5)
                            .glassEffect()
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Retire Candidates")
    }
}

struct StrugglingCardsFullList: View {
    let viewingSet: StudySet

    @AppStorage("weakMaxPercentCorrectEnabled") private var weakMaxPercentCorrectEnabled: Bool = true
    @AppStorage("weakMaxPercentCorrect") private var weakMaxPercentCorrect: Double = 0.6
    @AppStorage("weakMinTimeToFlipEnabled") private var weakMinTimeToFlipEnabled: Bool = true
    @AppStorage("weakMinTimeToFlipSeconds") private var weakMinTimeToFlipSeconds: Double = 8
    @AppStorage("weakRecallWindow") private var weakRecallWindow: Int = 25

    private struct RowItem: Identifiable {
        let id = UUID()
        let title: String
        let acc: Double
        let time: TimeInterval
    }

    private var items: [RowItem] {
        viewingSet.cards
            .enumerated()
            .filter { (_, card) in
                card.determineIfWeak(
                    maxPercentCorrect: weakMaxPercentCorrectEnabled ? weakMaxPercentCorrect : nil,
                    minTimeToFlip: weakMinTimeToFlipEnabled ? weakMinTimeToFlipSeconds : nil,
                    recallWindow: weakRecallWindow
                )
            }
            .map { (_, card) -> (title: String, acc: Double, time: TimeInterval) in
                let acc = card.stats.rollingPercentCorrect(recallWindow: weakRecallWindow)
                let time = card.stats.avgTimeToFlip(recallWindow: weakRecallWindow)
                return (title: card.front.text ?? "", acc: acc, time: time)
            }
            .sorted { l, r in
                if l.acc != r.acc { return l.acc < r.acc }
                return l.time > r.time
            }
            .map { tuple in
                RowItem(title: tuple.title, acc: tuple.acc, time: tuple.time)
            }
    }

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        ProgressView(value: item.acc)
                            .progressViewStyle(.linear)
                            .tint(.orange)
                        Text(String(format: "%.0f%%", item.acc * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1fs avg", item.time))
                            .font(.caption2)
                            .padding(5)
                            .glassEffect()
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Needs Practice")
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
        NavigationStack {
            ScrollView {
                RetireCandidatesCard(viewingSet: studySet)
                StrugglingCardsCard(viewingSet: studySet)
            }
        }
    }
    .padding()
}
