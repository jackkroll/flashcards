//
//  StatsView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//

import SwiftUI
import Charts

struct StatsView: View {
    let viewingSet : StudySet
    var body: some View {
            Chart {
                ForEach(viewingSet.cards, id: \.id) { card in
                    PointMark(
                        x: .value("Time to Answer", card.stats.avgTimeToFlip()),
                        y: .value("Percent Correct", card.stats.rollingPercentCorrect())
                    )
                }
            }
            .frame(maxWidth: 300, maxHeight: 300)
    }
}

#Preview {
    let studySet : StudySet = {
        let s = StudySet()
        for _ in 1...20 {
            let card = Card(front: "Hello", back: "World")
            for _ in 1...50 {
                card.stats.record(timeToFlip: .random(in: 2...20), gotCorrect: Bool.random())
            }
            s.cards.append(card)
        }
        
        return s
    }()
    StatsView(viewingSet: studySet)
}
