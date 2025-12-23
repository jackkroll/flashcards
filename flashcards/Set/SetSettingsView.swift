//
//  SetSettingsView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/17/25.
//

import SwiftUI
import SwiftData

struct SetSettingsView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let studySet: StudySet?
    @State private var setTitle: String = ""
    @State private var setDescription: String = ""
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Set Title"){
                        TextField("Title", text: $setTitle)
                    }
                    Section("Set Description (optional)"){
                        TextEditor(text: $setDescription)
                    }
                }
                .onAppear {
                    if let studySet = studySet {
                        setTitle = studySet.title
                        if let description = studySet.setDescription {
                            setDescription = description
                        }
                    }
                }
                VStack {
                    if let studySet = studySet {
                        Button("Update") {
                            studySet.title = setTitle
                            studySet.setDescription = setDescription
                            dismiss()
                        }
                    }
                    else {
                        Button("Create") {
                            let newSet = StudySet(title: setTitle, description: setDescription.isEmpty ? nil : setDescription)
                            modelContext.insert(newSet)
                            try? modelContext.save()
                            dismiss()
                        }
                        .tint(.green)
                        
                    }
                }
                .disabled(setTitle.isEmpty)
                .padding()
                .fontWeight(.semibold)
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
            }
            .toolbar {
                Button(role: .close) {
                    dismiss()
                }
            }
            .navigationTitle(studySet != nil ? "Update Set" : "Create Set")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Passed Set"){
    SetSettingsView(studySet: StudySet())
}

#Preview("Create Set"){
    SetSettingsView(studySet: nil)
}
