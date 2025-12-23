//
//  PlaySelectionView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/21/25.
//

import SwiftUI

struct PlaySelectionView: View {
    @EnvironmentObject var entitlement: EntitlementManager
    @AppStorage("lastStudyDate") private var lastStudyDate: Date = .distantPast
    @AppStorage("currentStreak") private var currentSteak: Int = 0
    let parentSet: StudySet
    @State var shuffle: Bool = true
    @State var focusOnWeakCards: Bool = false
    @State var includeStrongCards: Bool = true
    @State var lightningReview: Bool = false
    @State var numToReview: Float = 5
    @State private var modeSelected: AvailableModes = .flashcards
    var body: some View {
        VStack(spacing: 20){
            //Specific Mode Selection
            GroupBox {
                HStack {
                    Text("Review Mode Selection:")
                    Spacer()
                    Picker("Mode Selection",selection: $modeSelected) {
                        Text("Flashcards").tag(AvailableModes.flashcards)
                        Text("MCQ (Coming Soon)").tag(AvailableModes.mcq).selectionDisabled()
                    }
                    .pickerStyle(.menu)
                }
                VStack {
                    GroupBox("Flashcard Review") {
                        Text("Traditional flashcard review that you mark if you got correct or not.")
                    }
                }
            }
            Toggle(isOn: $shuffle, label: {
                Image(systemName: "shuffle")
                Text("Randomly Review Cards")
            })
            Toggle(isOn: $lightningReview, label: {
                Image(systemName: "bolt")
                Text("Review a small number of cards quickly")
            })
            if lightningReview && parentSet.cards.count > 2 {
                HStack {
                    Text("Cards: \(numToReview.formatted(.number))")
                        .contentTransition(.numericText())
                    Slider(value: $numToReview, in: 1...(Float(parentSet.cards.count) - 1), step: 1)
                }
                .onAppear {
                    withAnimation {
                        numToReview = Float(Int(parentSet.cards.count/2))
                    }
                }
            }
            if !shuffle && lightningReview {
                Text("This combination will lead to just the first \(numToReview.formatted(.number)) cards being reviewed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            Text("RECALL: PRO")
                .font(.caption)
                .fontWeight(.semibold)
                .monospaced()
                .foregroundStyle(.secondary)
            Group {
                Toggle(isOn: $focusOnWeakCards, label: {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("Focus on Weak Cards")
                })
                Toggle(isOn: $includeStrongCards, label: {
                    Image(systemName: "hand.thumbsup")
                    Text("Include Strong Cards")
                })
            }
            .disabled(!entitlement.hasPro)
            Spacer()
            NavigationLink {
                /*
                 var shouldShuffle : Bool = true
                 var subsetSize : Int? = nil
                 var shouldFocusOnWeakCards : Bool = false
                 var includeStrongCards : Bool = true
                 */
                StudyView(
                    studySet: parentSet,
                    shouldShuffle: shuffle,
                    subsetSize: lightningReview ? Int(numToReview) : nil,
                    shouldFocusOnWeakCards: focusOnWeakCards,
                    includeStrongCards: includeStrongCards
                )
                .onAppear {
                    if lastStudyDate.distance(to: .now) > 1.toDays {
                        lastStudyDate = .now
                        currentSteak += 1
                    }
                    parentSet.lastStudied = .now
                }
            } label: {
                Image(systemName: "play.fill")
                Text("Start review")
                    .fontWeight(.semibold)
            }
            .disabled(parentSet.cards.count == 0)
            .buttonSizing(.flexible)
            .buttonStyle(.glassProminent)
            .padding(.top, 50)
        }
        .padding()
        .onChange(of: focusOnWeakCards) {
            if focusOnWeakCards && includeStrongCards {
                withAnimation {
                    includeStrongCards = false
                }
            }
        }
        .onChange(of: includeStrongCards) {
            if focusOnWeakCards && includeStrongCards {
                withAnimation {
                    focusOnWeakCards = false
                }
            }
        }
        

    }
    
    enum AvailableModes {
        case flashcards
        case mcq
    }
}

#Preview {
    let set = StudySet()
    for _ in 0...20 {
        set.cards.append(Card(front: "Hello", back: "World"))
    }
    return NavigationStack {
        PlaySelectionView(parentSet: set)
    }
    .environmentObject(EntitlementManager())
}
