//
//  StudyView.swift
//  todo
//
//  Created by Jack Kroll on 12/16/25.
//

import SwiftUI

struct StudyView: View {
    let studySet : StudySet
    @EnvironmentObject var entitlement: EntitlementManager
    @State var visibleCards: [Card] = []
    @State private var undoStack: [Card] = []
    @State private var correctStack: [Card] = []
    @State private var incorrectStack: [Card] = []
    @State private var dragOffset: CGSize = .zero
    @State private var hesitationTimeStart: Date = .now
    var body: some View {
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    if studySet.cards.isEmpty {
                        ContentUnavailableView {
                            Label("No Cards to Study!", systemImage: "star.fill")
                        } description: {
                            Text("Great work! You completed a study set!")
                            Text("\(correctStack.count) correct, \(incorrectStack.count) incorrect.")
                        }
                    }
                    if visibleCards.isEmpty && studySet.cards.count > 0 {
                        ContentUnavailableView {
                            Label("Study Session Completed", systemImage: "star.fill")
                        } description: {
                            Text("Great work! You completed a study set!")
                            Text("\(correctStack.count) correct, \(incorrectStack.count) incorrect.")
                        }
                    }
                    ForEach(Array(visibleCards.enumerated()), id: \.element) { index, card in
                        let topIndex = visibleCards.count - 1
                        let isTop = index == topIndex
                        let depth = max(0, topIndex - index)
                        let baseScale = 1.0 - min(0.25 * Double(depth), 0.10)
                        let peekBoost = min(abs(dragOffset.width) / (size.width * 2), 0.04)
                        let scale = isTop ? 1.0 : baseScale + peekBoost
                        let yOffset = CGFloat(depth) * 7
                        
                        CardView(card: card)
                            .padding()
                            .overlay {
                                // Green (right) / Red (left) edge gradients that grow with horizontal drag
                                GeometryReader { proxy in
                                    ZStack {
                                        // Right swipe (green) overlay
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: .clear, location: 0.0),
                                                .init(color: Color.green.opacity(0.15), location: 0.35),
                                                .init(color: Color.green.opacity(0.35), location: 0.7),
                                                .init(color: Color.green.opacity(0.6), location: 1.0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(width: proxy.size.width * min(max(dragOffset.width, 0) / (size.width * 0.25), 1))
                                        .frame(maxHeight: .infinity)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .opacity(isTop && dragOffset.width > 0 ? 1 : 0)
                                        
                                        // Left swipe (red) overlay
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color.red.opacity(0.6), location: 0.0),
                                                .init(color: Color.red.opacity(0.35), location: 0.3),
                                                .init(color: Color.red.opacity(0.15), location: 0.65),
                                                .init(color: .clear, location: 1.0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(width: proxy.size.width * 0.6 * min(max(-dragOffset.width, 0) / (size.width * 0.25), 1))
                                        .frame(maxHeight: .infinity)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(isTop && dragOffset.width < 0 ? 1 : 0)
                                    }
                                }
                                .allowsHitTesting(false)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .padding()
                            }
                            .scaleEffect(scale)
                            .offset(x: isTop ? dragOffset.width : 0,
                                    y: (isTop ? dragOffset.height : 0) + yOffset)
                            .rotationEffect(.degrees(Double((isTop ? dragOffset.width : 0) / size.width) * 15),
                                            anchor: .bottom)
                            .shadow(color: .black.opacity(0.08), radius: isTop ? 12 : 6, x: 0, y: 6)
                            .zIndex(Double(index))
                            .allowsHitTesting(isTop)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if isTop {
                                            dragOffset = value.translation
                                        }
                                    }
                                    .onEnded { value in
                                        guard isTop else { return }
                                        let threshold = size.width * 0.25
                                        let translation = value.translation
                                        let direction: CGFloat = translation.width > threshold ? 1 :
                                        (translation.width < -threshold ? -1 : 0)
                                        
                                        if direction != 0 {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2)) {
                                                dragOffset = CGSize(width: direction * size.width * 1.5, height: translation.height)
                                            }
                                            
                                            let instanceHesitationTime = Date.now.distance(to: hesitationTimeStart)
                                            if direction > 0 {
                                                //Swipe Right
                                                card.stats.record(timeToFlip: instanceHesitationTime, gotCorrect: true)
                                                correctStack.append(card)
                                            }
                                            else {
                                                //Swipe Left
                                                card.stats.record(timeToFlip: instanceHesitationTime, gotCorrect: false)
                                                incorrectStack.append(card)
                                            }
                                            
                                            //card.stats?.addTimeToFlip(Date.now.distance(to: hesitationTimeStart))
                                            hesitationTimeStart = .now
                                            withAnimation {
                                                if let removed = visibleCards.popLast() {
                                                    undoStack.append(removed)
                                                }
                                                dragOffset = .zero
                                            }
                                        } else {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .onAppear {
                if visibleCards.isEmpty {
                    visibleCards = Array(studySet.cards.reversed())
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: visibleCards.isEmpty ? resetStack : undoLastThrow) {
                        Label("Undo", systemImage: visibleCards.isEmpty ? "arrow.trianglehead.2.clockwise.rotate.90" : "arrow.uturn.left")
                    }
                    .disabled(undoStack.isEmpty)
                    Spacer()
                    
                }
                ToolbarItem(placement: .topBarTrailing){
                    if entitlement.hasPro {
                        NavigationLink(destination: StatsView(viewingSet: studySet)){
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                    else {
                        NavigationLink(destination: StoreView()){
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                }
                
            }
            .navigationTitle(studySet.title)
            .navigationBarTitleDisplayMode(.inline)
        }
}

extension StudyView {
    private func undoLastThrow() {
        guard let last = undoStack.popLast() else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            dragOffset = .zero
            visibleCards.append(last)
        }
    }
    
    private func resetStack() {
        correctStack = []
        incorrectStack = []
        while !undoStack.isEmpty {
            undoLastThrow()
        }
    }
}

#Preview{
    let set: StudySet = {
        let s = StudySet()
        for _ in 1...3 {
            s.cards.append(Card(front: "Hello", back: "World"))
        }
        return s
    }()

    StudyView(studySet: set)
        .environmentObject(EntitlementManager())
}

