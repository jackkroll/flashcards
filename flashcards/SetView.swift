//
//  SetView.swift
//  todo
//
//  Created by Jack Kroll on 11/25/25.
//

import SwiftUI
import FoundationModels
import SwiftData
import PhotosUI

struct SetView: View {
    @Bindable var set: StudySet
    @State var isAddCardSheetDisplayed: Bool = false
    @State var genCardSheetDisplayed: Bool = false
    @State var cardViewDislayed: Bool = false
    @State var isStudying: Bool = false
    //@Namespace var namespace
    var body: some View {
            VStack {
                if set.cards.isEmpty {
                    ContentUnavailableView {
                        Label("No cards in this set", systemImage: "rectangle.fill.on.rectangle.angled.fill")
                    } description: {
                        Text("Create some cards to get started.")
                    }
                }
                if cardViewDislayed {
                    TabView {
                        ForEach(set.cards){ card in
                            CardView(card: card)
                                .padding()
                            //.matchedGeometryEffect(id: card.id, in: namespace)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                else {
                    VStack(spacing: 10) {
                        ScrollView {
                            ForEach(set.cards){ card in
                                CardView(card: card)
                                    .frame(height: 150)
                                //.matchedGeometryEffect(id: card.id, in: namespace)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $isAddCardSheetDisplayed) {
                AddCardView(parentSet: set)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $genCardSheetDisplayed) {
                GenerableAddCardView(parentSet: set)
                    .interactiveDismissDisabled()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isAddCardSheetDisplayed = true
                    } label : {
                        Image(systemName: "plus")
                    }
                    
                    Button {
                        genCardSheetDisplayed = true
                    } label : {
                        Image(systemName: "apple.intelligence")
                            .symbolRenderingMode(.multicolor)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button{
                        withAnimation {
                            cardViewDislayed.toggle()
                        }
                    } label : {
                        Image(systemName: cardViewDislayed ? "list.bullet" : "rectangle.portrait.on.rectangle.portrait")
                            .contentTransition(.symbolEffect(.replace))
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            isStudying = true
                        }
                    } label: {
                        Image(systemName: "play.fill")
                    }
                }
            }
            .navigationDestination(isPresented: $isStudying) {
                StudyView(studySet: set)
            }
            .navigationTitle(set.title)
            .navigationBarTitleDisplayMode(.inline)
    }
        
}

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
        NavigationStack {
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

struct AddCardView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let parentSet: StudySet
    @State var frontText: String = ""
    @State var frontType : SingleSide.SideType = .text
    @State var selectedPhotoFront: PhotosPickerItem? = nil
    @State var selectedImageFront: Image? = nil
 
    
    @State var backText: String = ""
    @State var backType : SingleSide.SideType = .text
    
    @State var selectedPhotoBack: PhotosPickerItem? = nil
    @State var selectedImageBack: Image? = nil
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Front"){
                        Picker("Content Type", selection: $frontType) {
                            ForEach(SingleSide.SideType.allCases, id: \.rawValue) { type in
                                Text(String(describing: type).capitalized(with: Locale.current))
                                    .tag(type)
                            }
                        }
                        switch frontType {
                        case .text:
                            TextField("Term/Question", text: $frontText)
                        case .image:
                            PhotosPicker(selection: $selectedPhotoFront) {
                                if let selectedImageFront = selectedImageFront {
                                    selectedImageFront
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                }
                                Text("Select a photo")
                            }
                            .onChange(of: selectedPhotoFront) {
                                Task {
                                    if let selectedPhotoFront = selectedPhotoFront {
                                        if let imgData = try? await selectedPhotoFront.loadTransferable(type: Data.self) {
                                            if let uiImg = UIImage(data: imgData) {
                                                selectedImageFront = Image(uiImage: uiImg)
                                            }
                                        }
                                    }
                                }
                            }
                        case .audio:
                            EmptyView()
                        }
                        
                    }
                    Section("Back") {
                        Picker("Content Type", selection: $backType) {
                            ForEach(SingleSide.SideType.allCases, id: \.rawValue) { type in
                                Text(String(describing: type).capitalized(with: Locale.current))
                                    .tag(type)
                            }
                        }
                        
                        switch backType {
                        case .text:
                            TextField("Definition/Answer", text: $backText)
                        case .image:
                            PhotosPicker(selection: $selectedPhotoBack) {
                                if let selectedImageBack = selectedImageBack {
                                    selectedImageBack
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                }
                                Text("Select a photo")
                            }
                            .onChange(of: selectedPhotoBack) {
                                Task {
                                    if let selectedPhotoBack = selectedPhotoBack {
                                        if let imgData = try? await selectedPhotoBack.loadTransferable(type: Data.self) {
                                            if let uiImg = UIImage(data: imgData) {
                                                selectedImageBack = Image(uiImage: uiImg)
                                            }
                                        }
                                    }
                                }
                            }
                        case .audio:
                            EmptyView()
                        }
                    }
                    
                }
                Button("Add Card") {
                    dismiss()
                    Task(priority: .userInitiated){
                        var sideA: SingleSide? = nil
                        switch frontType {
                        case .text:
                            sideA = SingleSide(text: frontText)
                        case .image:
                            if let img = selectedImageFront {
                                sideA = SingleSide(img: img)
                            }
                        case .audio:
                            sideA = nil
                        }
                        
                        var sideB: SingleSide? = nil
                        switch backType {
                        case .text:
                            sideB = SingleSide(text: backText)
                        case .image:
                            if let img = selectedImageBack {
                                sideB = SingleSide(img: img)
                            }
                        case .audio:
                            sideB = nil
                        }
                        
                        if let sideA, let sideB {
                            let card = Card(front: sideA, back: sideB)
                            parentSet.cards.append(card)
                            try? modelContext.save()
                        }
                    }
                }
                .disabled(!canAdd())
                .fontWeight(.semibold)
                .buttonSizing(.flexible)
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(role: .close) {
                    dismiss()
                }
            }
        }
    }
    
    func canAdd() -> Bool {
        switch frontType {
        case .text:
            if frontText.isEmpty {
                return false
            }
        case .image:
            if selectedImageFront == nil {
                return false
            }
        case .audio:
            return false
        }
        
        switch backType {
        case .text:
            if backText.isEmpty {
                return false
            }
        case .image:
            if selectedImageBack == nil {
                return false
            }
        case .audio:
            return false
        }
        
        return true
    }
}

#Preview {
    let set: StudySet = {
        let s = StudySet()
        for _ in 1...20 {
            s.cards.append(Card(front: "Hello", back: "World"))
        }
        return s
    }()
    NavigationStack {
        SetView(set: set)
    }
}

#Preview("Add Card Sheet") {
    AddCardView(parentSet: StudySet())
        .modelContainer(for: StudySet.self, inMemory: true)
}

#Preview("Generate Card View") {
    GenerableAddCardView(parentSet: StudySet())
}

