//
//  AddCardView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//
import SwiftUI
import SwiftData
import PhotosUI

struct AddCardView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let parentSet: StudySet
    var parentCard: Card? = nil
    @State var frontText: String = ""
    @State var frontType : SingleSide.SideType = .text
    @State var selectedPhotoFront: PhotosPickerItem? = nil
    @State var selectedImageFront: Image? = nil
 
    
    @State var backText: String = ""
    @State var backType : SingleSide.SideType = .text
    
    @State var selectedPhotoBack: PhotosPickerItem? = nil
    @State var selectedImageBack: Image? = nil
    var body: some View {
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
                VStack {
                    Button(parentCard != nil ? "Update Card" : "Add Card") {
                        dismiss()
                        Task(priority: .userInitiated){
                            await addCard()
                        }
                    }
                    .disabled(!canAdd())
                    .fontWeight(.semibold)
                    .buttonSizing(.flexible)
                    .buttonStyle(.borderedProminent)
                    .tint(parentCard != nil ? .blue : .green)
                    if parentCard == nil {
                        Button("Add Card + Continue Adding") {
                            Task(priority: .userInitiated) {
                                await addCard()
                                withAnimation {
                                    frontText = ""
                                    backText = ""
                                    selectedPhotoFront = nil
                                    selectedImageFront = nil
                                    selectedPhotoBack = nil
                                    selectedImageBack = nil
                                }
                            }
                        }
                        .disabled(!canAdd())
                        .fontWeight(.semibold)
                        .buttonSizing(.flexible)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(role: .close) {
                    dismiss()
                }
            }
            .onAppear {
                if let card = parentCard {
                    switch card.front.sideType {
                    case .text:
                        frontText = card.front.text ?? ""
                    case .image:
                        selectedImageFront = card.front.fetchImage()
                    case .audio:
                        break
                    }
                    
                    switch card.back.sideType {
                    case .text:
                        backText = card.back.text ?? ""
                    case .image:
                        selectedImageBack = card.back.fetchImage()
                    case .audio:
                        break
                    }
                }
            }
    }
    
    func addCard() async {
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
            if let parentCard = parentCard {
                parentCard.front = sideA
                parentCard.back = sideB
            }
            else {
                parentSet.cards.append(card)
            }
                
            try? modelContext.save()
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

#Preview("Add Card Sheet") {
    AddCardView(parentSet: StudySet())
        .modelContainer(for: StudySet.self, inMemory: true)
}
