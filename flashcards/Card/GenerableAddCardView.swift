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
    @State var expansion : GenerableStudySetExpansion.PartiallyGenerated? = nil
    @State var completedCards : [Card] = []
    let parentSet: StudySet
    @State private var errorMessage: String? = nil
    var body: some View {
        if !SystemLanguageModel.default.isAvailable {
            ContentUnavailableView {
                Label("Apple Intelligence Not Available", systemImage: "apple.intelligence.badge.xmark")
            } description: {
                switch SystemLanguageModel.default.availability {
                case .unavailable(.appleIntelligenceNotEnabled):
                    Text("The model is not enabled on your device")
                case .unavailable(.deviceNotEligible):
                    Text("Your device is not eligible for this model")
                case .unavailable(.modelNotReady):
                    Text("The device model is not ready yet, check back later")
                default:
                    Text("Unknown availability")
                }

            }
        }
        else if !SystemLanguageModel.default.supportsLocale() {
            ContentUnavailableView {
                Label("Apple Intelligence Not Available", systemImage: "apple.intelligence.badge.xmark")
            } description: {
                Text("This model does not currently support this device's locale")
            }
        }
        else {
            VStack {
                    if let msg =  errorMessage {
                        HStack {
                            Text(msg)
                                .bold()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassEffect()
                        .animation(.easeInOut, value: errorMessage)
                        
                    }
                if expansion == nil {
                    ContentUnavailableView {
                        Label("Create some Cards", systemImage: "sparkles")
                    } description: {
                        Text("Utilize Apple Intelligence to generate cards to study with")
                    }
                }
                ScrollView {
                    ForEach(expansion?.cards ?? [], id: \.id) { card in
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
                if expansion == nil {
                    TextField(text: $cardsPrompt) {
                        Text("Prompt for flashcards")
                    }
                    .onSubmit {
                        if !cardsPrompt.isEmpty || isGenerating {
                            Task {
                                await generateCards()
                            }
                        }
                    }
                    .focused($promptFieldIsFocused)
                    .onAppear {
                        promptFieldIsFocused = true
                    }
                    .submitLabel(.done)
                    
                    Button("Generate") {
                        Task {
                                await generateCards()
                        }
                    }
                    .disabled(cardsPrompt.isEmpty || isGenerating)
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.glassProminent)
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
                    .buttonStyle(.glassProminent)
                    .tint(.green)
                    
                    Button("Regenerate") {
                        Task(priority: .userInitiated){
                            withAnimation {
                                completedCards = []
                                isGenerating = true
                            }
                            let stream = session.streamResponse(to: "The user rejected the previous cards, create a new set of them", generating: GenerableStudySetExpansion.self)
                            for try await partial in stream {
                                await MainActor.run {
                                    withAnimation { self.expansion = partial.content }
                                }
                            }
                            let finishedCards = try? await stream.collect().content
                            await MainActor.run {
                                withAnimation {
                                    // Update partials one last time if available
                                    if let finished = finishedCards {
                                        self.completedCards = finished.toCards()
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
                    .buttonStyle(.glass)
                }
            }
            .padding()
            .toolbar {
                Button(role: .close) {
                    dismiss()
                }
            }
        }
    }
    func generateCards() async {
        withAnimation {
            isGenerating = true
        }
        let cardsPrompt = parentSet.setTextualRepresentation() + "User Request: \(cardsPrompt)" + "You should create entirely new cards, do NOT create any duplicates that were described above, only new cards. Please ensure that the content of the cards you generate strictly abide by the users prompt for each card generated."
        do {
            let stream = session.streamResponse(to: cardsPrompt, generating: GenerableStudySetExpansion.self)
            for try await partial in stream {
                await MainActor.run {
                    withAnimation { self.expansion = partial.content }
                }
            }
            let finishedCards = try? await stream.collect().content
            await MainActor.run {
                withAnimation {
                    // Update partials one last time if available
                    if let finished = finishedCards {
                        self.completedCards = finished.toCards()
                    }
                    self.isGenerating = false
                }
            }
        }
        catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            errorMessage = "Unsupported Locale or Language"
        }
        catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            errorMessage = "Context Window Exceeded"
        }
        catch LanguageModelSession.GenerationError.refusal {
            errorMessage = "Generation Refused by Model"
        }
        catch LanguageModelSession.GenerationError.guardrailViolation {
            errorMessage = "Model Indicated Guardrail Violation"
        }
        catch {
            errorMessage = error.localizedDescription
        }
        if errorMessage != nil {
            self.isGenerating = false
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
