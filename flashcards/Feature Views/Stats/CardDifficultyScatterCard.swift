//
//  CardDifficultyScatterCard.swift
//  flashcards
//
//  Scatter plot of per-card difficulty: X = Avg Time (s), Y = Accuracy (%).
//

import SwiftUI
import Charts

struct CardDifficultyScatterCard: View {
    let viewingSet: StudySet
    let window: Int
    @State private var selectedDot: Dot?
    @State private var selectedCard: Card?

    
    private struct Dot: Identifiable {
        let id = UUID()
        let index: Int
        let time: Double
        let accuracyPct: Double
        let card: Card
    }
    
    private var dots: [Dot] {
        viewingSet.cards.enumerated().map { (idx, card) in
            let t = card.stats.avgTimeToFlip(recallWindow: window)
            let a = card.stats.rollingPercentCorrect(recallWindow: window) * 100
            return Dot(index: idx, time: t, accuracyPct: a, card: card)
        }
    }
    
    var body: some View {
        InfoCard(title: "Per-Card Difficulty", subtitle: "Rolling Avg: last \(window)") {
            VStack {
            if viewingSet.cards.flatMap({ $0.stats.recordedStats }).isEmpty {
                ContentUnavailableView {
                    Label("No Cards", systemImage: "point.3.connected.trianglepath.dotted")
                } description: {
                    Text("Add cards to compare difficulty.")
                }
            } else {
                Chart {
                    ForEach(dots) { d in
                        PointMark(
                            x: .value("Avg Time (s)", d.time),
                            y: .value("Accuracy (%)", d.accuracyPct)
                        )
                        .foregroundStyle(.blue)
                        //.opacity(selectedDot?.index == d.index ? 1 : 0.3)
                    }
                    if let selectedDot {
                        RuleMark(x: .value("Selected Time", selectedDot.time))
                            .foregroundStyle(.primary)
                            .opacity(0.8)
                        
                        RuleMark(y: .value("Selected Accuracy", selectedDot.accuracyPct))
                            .foregroundStyle(.primary)
                            .opacity(0.8)
                    }
                    
                }
                .frame(height: 220)
                .chartXScale(range: .plotDimension(padding: 5))
                .chartXAxisLabel("Avg Time (s)")
                .chartYAxisLabel("Accuracy (%)")
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let location = value.location
                                        
                                        guard
                                            let time: Double = proxy.value(atX: location.x),
                                            let accuracy: Double = proxy.value(atY: location.y)
                                        else { return }
                                        
                                       
                                        selectedDot = dots.min(by: {
                                            hypot($0.time - time, $0.accuracyPct - accuracy) <
                                                hypot($1.time - time, $1.accuracyPct - accuracy)
                                        })
                                        
                                        withAnimation {
                                            if let card = selectedDot?.card {
                                                selectedCard = card
                                            }
                                        }
                                        
                                    }
                                
                            )
                    }
                }
                if selectedDot != nil {
                    CardView(card: selectedCard)
                        .id(selectedCard?.id)
                        .frame(height: 200)
                    Button("Clear Selection") {
                        withAnimation {
                            selectedDot = nil
                        }
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
        for i in 1...12 {
            let c = Card(front: "Card #\(i)", back: "B")
            for _ in 0..<40 { c.stats.record(timeToFlip: .random(in: 2...10), gotCorrect: Bool.random()) }
            s.cards.append(c)
        }
        return s
    }()
    return CardDifficultyScatterCard(viewingSet: studySet, window: 25)
}
