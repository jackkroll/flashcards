//
//  GenerableAddCardView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//
import SwiftUI
import SwiftData
import FoundationModels

struct GenerableAddCardView : View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @FocusState private var promptFieldIsFocused: Bool
    @State var isGenerating = false
    @State var cardsPrompt: String = ""
    let session = LanguageModelSession(model: .default)
    @State var cards : [GenerableCard.PartiallyGenerated] = []
    @State var completedCards : [Card] = []
    let parentSet: StudySet
    var body: some View {
            VStack {
                if cards.isEmpty {
                    ContentUnavailableView {
                        Label("Create some Cards", systemImage: "sparkles")
                    } description: {
                        Text("Utilize Apple Intelligence to generate cards to study with")
                    }
                }
                ScrollView {
                    ForEach(cards, id: \.id) { card in
                           HStack {
                               GenerableCardView(card: card)
                               if completedCards.contains(where: {
                                   $0.front.text == (card.front ?? "") &&
                                   $0.back.text == (card.back ?? "")})
                               {
                                   Button {
                                       if parentSet.cards.contains(where: {
                                           $0.front.text == (card.front ?? "") &&
                                           $0.back.text == (card.back ?? "")}) {
                                           withAnimation {
                                               parentSet.cards.removeAll(where: {
                                                   $0.front.text == (card.front ?? "") &&
                                                   $0.back.text == (card.back ?? "")})
                                               try? modelContext.save()
                                           }
                                       }
                                       else {
                                           withAnimation {
                                               parentSet.cards.append(Card(front: card.front ?? "", back: card.back ?? ""))
                                               try? modelContext.save()
                                           }
                                       }
                                   } label : {
                                       Image(systemName: parentSet.cards.contains(where: {
                                           $0.front.text == (card.front ?? "") &&
                                           $0.back.text == (card.back ?? "")}) ?
                                            "checkmark" : "plus")
                                       .resizable()
                                       .scaledToFit()
                                       .frame(width: 20, height: 20)
                                       .padding()
                                       .background(Material.bar)
                                       .clipShape(Circle())
                                       .contentTransition(.symbolEffect(.replace))
                                   }
                               }
                           }
                           .frame(height: 200)
                       }
                }
                if cards.isEmpty {
                TextField(text: $cardsPrompt) {
                    Text("Prompt for flashcards")
                }
                .focused($promptFieldIsFocused)
                .onAppear {
                    promptFieldIsFocused = true
                }
                .submitLabel(.done)
                
                    Button("Generate") {
                        Task {
                            withAnimation {
                                isGenerating = true
                            }
                            let cardsPrompt = parentSet.setTextualRepresentation() + "User Request: \(cardsPrompt)" + "You should create entirely new cards, do NOT create any duplicates that were described above, only new cards. Please ensure that the content of the cards you generate strictly abide by the users prompt for each card generated."
                            let stream = session.streamResponse(to: cardsPrompt, generating: [GenerableCard].self)
                            for try await partial in stream {
                                await MainActor.run {
                                    withAnimation { self.cards = partial.content }
                                }
                            }
                            let finishedCards = try? await stream.collect().content
                            await MainActor.run {
                                withAnimation {
                                    // Update partials one last time if available
                                    if let finished = finishedCards {
                                        self.completedCards = finished.compactMap { gen in
                                            gen.asCard()
                                        }
                                    }
                                    self.isGenerating = false
                                }
                            }
                        }
                    }
                    .disabled(cardsPrompt.isEmpty || isGenerating)
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.borderedProminent)
                }
                else {
                    Text("Generated content may contain errors, double check important information")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Save") {
                        dismiss()
                        Task(priority: .userInitiated){
                            for card in completedCards {
                                if !parentSet.cards.contains(card) {
                                    parentSet.cards.append(card)
                                }
                            }
                            try? modelContext.save()
                        }
                    }
                    .disabled(isGenerating || completedCards == [])
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Regenerate") {
                        Task(priority: .userInitiated){
                            withAnimation {
                                completedCards = []
                                isGenerating = true
                            }
                            let stream = session.streamResponse(to: "The user rejected the previous cards, create a new set of them", generating: [GenerableCard].self)
                            for try await partial in stream {
                                await MainActor.run {
                                    withAnimation { self.cards = partial.content }
                                }
                            }
                            let finishedCards = try? await stream.collect().content
                            await MainActor.run {
                                withAnimation {
                                    // Update partials one last time if available
                                    if let finished = finishedCards {
                                        self.completedCards = finished.compactMap { gen in
                                            gen.asCard()
                                        }
                                    }
                                    self.isGenerating = false
                                }
                            }
                        }
                    }
                    .disabled(isGenerating || completedCards == [])
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .toolbar {
                Button(role: .close) {
                    dismiss()
                }
            }
    }
    func cardsContainGenerableCard(genCard: GenerableCard?, cards: [Card]) -> Bool {
        /*if !parentSet.cards.contains(where: {
            $0.front.text == (card.front ?? "") &&
            $0.back.text == (card.back ?? "")}) {
            parentSet.cards.append(card)
        }*/
        if cards.contains(where: {
            $0.front.text == (genCard?.front ?? "") &&
            $0.back.text == (genCard?.back ?? "")
        }) {
            return true
        }
        else {
            return false
        }
    }
}

#Preview("Generate Card View") {
    GenerableAddCardView(parentSet: StudySet())
}
