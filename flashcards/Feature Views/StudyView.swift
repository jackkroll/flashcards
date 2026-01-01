//
//  StudyView.swift
//  todo
//
//  Created by Jack Kroll on 12/16/25.
//

import SwiftUI
import SwiftData

struct StudyView: View {
    let studySet : StudySet
    var shouldShuffle : Bool = false
    var subsetSize : Int? = nil
    var shouldFocusOnWeakCards : Bool = false
    var includeStrongCards : Bool = true
    
    @EnvironmentObject var entitlement: EntitlementManager
    @EnvironmentObject var router: Router
    @AppStorage("lastStudyDate") private var lastStudyDate: Date = .distantPast
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    
    @AppStorage("strongMinPercentCorrectEnabled") private var strongMinPercentCorrectEnabled: Bool = true
    @AppStorage("strongMinPercentCorrect") private var strongMinPercentCorrect: Double = 0.8
    @AppStorage("strongMaxTimeToFlipEnabled") private var strongMaxTimeToFlipEnabled: Bool = false
    @AppStorage("strongMaxTimeToFlipSeconds") private var strongMaxTimeToFlipSeconds: Double = 5
    @AppStorage("strongRecallWindow") private var strongRecallWindow: Int = 10
    
    @AppStorage("weakMaxPercentCorrectEnabled") private var weakMaxPercentCorrectEnabled: Bool = true
    @AppStorage("weakMaxPercentCorrect") private var weakMaxPercentCorrect: Double = 0.6
    @AppStorage("weakMinTimeToFlipEnabled") private var weakMinTimeToFlipEnabled: Bool = false
    @AppStorage("weakMinTimeToFlipSeconds") private var weakMinTimeToFlipSeconds: Double = 3
    @AppStorage("weakRecallWindow") private var weakRecallWindow: Int = 10
    
    @State var visibleCards: [Card] = []
    @State private var undoStack: [Card] = []
    @State private var correctStack: [Card] = []
    @State private var incorrectStack: [Card] = []
    @State private var dragOffset: CGSize = .zero
    @State private var hesitationTimeStart: Date = .now
    @State private var studyStartTime: Date? = nil
    var body: some View {
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    if studySet.cards.isEmpty {
                        VStack {
                            ContentUnavailableView {
                                Label("No Cards to Study", systemImage: "exclamationmark.magnifyingglass")
                            } description: {
                                Text("You have no cards in this study set ")
                            }
                        }
                    }
                    if visibleCards.isEmpty && undoStack.isEmpty {
                        ContentUnavailableView {
                            Label("No Cards to Study", systemImage: "star.fill")
                        } description: {
                            Text("With your current settings, there are no cards that need to be studied!")
                        }
                    }
                    if visibleCards.isEmpty && undoStack.count > 0 {
                        VStack {
                            ContentUnavailableView {
                                Label("Study Session Completed", systemImage: "star.fill")
                            } description: {
                                Text("Great work! You completed a study set!")
                                Text("\(correctStack.count) correct, \(incorrectStack.count) incorrect.")
                                Button("Return to set") {
                                    router.pop()
                                }
                                .buttonStyle(.glass)
                            }
                            
                        }
                    }
                    ForEach(visibleCards.enumerated(), id: \.element) { index, card in
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
                                            
                                            let instanceHesitationTime = abs(Date.now.distance(to: hesitationTimeStart))
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
                Task {
                    // Streak updating
                    let calendar = Calendar.current
                    if calendar.isDateInYesterday(lastStudyDate) {
                        currentStreak += 1
                    } else {
                        // missed one or more days (or first time): start a new streak
                        currentStreak = 1
                    }
                    lastStudyDate = .now
                    
                    studySet.lastStudied = .now
                    
                    studyStartTime = .now
                    if visibleCards.isEmpty {
                        var baseArr : [Card] = studySet.cards
                        baseArr.reverse()
                        if shouldShuffle {
                            baseArr.shuffle()
                        }
                        if let stackSize = subsetSize {
                            baseArr = Array(baseArr.prefix(stackSize))
                        }
                        
                        // Pro features, remove strong cards from set
                        if !includeStrongCards {
                            baseArr = baseArr.filter { card in
                                !card.determineIfStrong(
                                    minPercentCorrect: strongMinPercentCorrectEnabled ? strongMinPercentCorrect : nil,
                                    maxTimeToFlip: strongMaxTimeToFlipEnabled ? strongMaxTimeToFlipSeconds : nil,
                                    recallWindow: strongRecallWindow
                                )
                            }
                        }
                        
                        // Pro Feature, only include weak cards
                        if shouldFocusOnWeakCards {
                            baseArr = baseArr.filter { card in
                                card.determineIfWeak(
                                    maxPercentCorrect: weakMaxPercentCorrectEnabled ? weakMaxPercentCorrect : nil,
                                    minTimeToFlip: weakMinTimeToFlipEnabled ? weakMinTimeToFlipSeconds : nil,
                                    recallWindow: weakRecallWindow
                                )
                            }
                        }
                         
                        visibleCards = baseArr
                        
                    }
                }
            }
            .onDisappear {
                if let startTime = studyStartTime {
                    studySet.stats.totalStudyTime += startTime.distance(to: .now)
                    studyStartTime = nil
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
                ToolbarItem(placement: .bottomBar){
                    if entitlement.hasPro {
                        Button {
                            router.push(.stats(setID: studySet.persistentModelID))
                        } label: {
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                    else {
                        Button {
                            router.push(.proCompare)
                        } label: {
                            Image(systemName: "chart.bar")
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
        for num in 1...20 {
            s.cards.append(Card(front: num.formatted(.number), back: "Back"))
        }
        return s
    }()


    return NavigationStack {
        StudyView(studySet: set)
    }
    .environmentObject(EntitlementManager())
    .environmentObject(Router())
}

