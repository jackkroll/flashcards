//
//  GenerateSetView.swift
//  todo
//
//  Created by Jack Kroll on 11/25/25.
//

import SwiftUI
import FoundationModels
import SwiftData

struct GenerateSetView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    var session = LanguageModelSession(model: .default)
    @FocusState private var promptFieldIsFocused: Bool
    @State var isGenerating = false
    @State var setPrompt: String = ""
    @State var set : GenerableSet.PartiallyGenerated? = nil
    @State var completedSet : StudySet? = nil
    @State private var errorMessage: String? = nil
    var body: some View {
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
                if set != nil {
                    GroupBox(set!.title ?? "Untitled") {
                        if set!.description != nil && !set!.description!.isEmpty {
                            Text(set!.description!)
                        }
                    }
                    VStack {
                        ScrollView {
                            ForEach(set?.cards ?? []) { card in
                                GenerableCardView(card: card)
                                    .frame(height: 200)
                            }
                        }
                    }
                    Text("Generated content may contain errors, double check important information")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Save") {
                        if let completedSet = completedSet {
                            modelContext.insert(completedSet)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                    .disabled(isGenerating || completedSet == nil)
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.glassProminent)
                    .tint(.green)
                    Button("Regenerate") {
                        Task {
                            errorMessage = nil
                            withAnimation {
                                completedSet = nil
                                isGenerating = true
                            }
                            do {
                                let stream = session.streamResponse(to: "The user rejected the previous set, create a different one", generating: GenerableSet.self)
                                for try await partial in stream {
                                    await MainActor.run {
                                        withAnimation { self.set = partial.content }
                                    }
                                }
                                // then collect final if supported, on main actor
                                let finishedSet = try? await stream.collect().content
                                await MainActor.run {
                                    withAnimation {
                                        self.set = finishedSet?.asPartiallyGenerated()
                                        self.completedSet = finishedSet?.exportToStudySet()
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
                    }
                    .disabled(isGenerating || completedSet == nil)
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.glass)

                }
                /*if isGenerating && set == nil {
                    ForEach(1...5, id: \.self ) { _ in
                        CardView(card: nil)
                    }
                    
                }*/
                if !isGenerating && set == nil {
                    ContentUnavailableView {
                        Label("Create a set", systemImage: "sparkles")
                    } description: {
                        Text("Utilize Apple Intelligence to create a set of flashcards")
                    }
                    Spacer()
                    TextField(text: $setPrompt) {
                        Text("Prompt for flashcards")
                    }
                    .focused($promptFieldIsFocused)
                    .onAppear {
                        promptFieldIsFocused = true
                    }
                    .submitLabel(.done)
                    
                    Button("Generate") {
                        Task {
                            errorMessage = nil
                            withAnimation {
                                isGenerating = true
                            }
                            do {
                                let stream = session.streamResponse(to: setPrompt, generating: GenerableSet.self)
                                for try await partial in stream {
                                    await MainActor.run {
                                        withAnimation { self.set = partial.content }
                                    }
                                }
                                
                                let finishedSet = try? await stream.collect().content
                                await MainActor.run {
                                    withAnimation {
                                        self.set = finishedSet?.asPartiallyGenerated()
                                        self.completedSet = finishedSet?.exportToStudySet()
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
                    }
                    .disabled(setPrompt.isEmpty || isGenerating)
                    .fontWeight(.semibold)
                    .font(.title3)
                    .buttonSizing(.flexible)
                    .buttonStyle(.glassProminent)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
             
    }
}

#Preview {
    NavigationStack {
        GenerateSetView()
    }
    
}
