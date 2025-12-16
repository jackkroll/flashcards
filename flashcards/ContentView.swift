//
//  ContentView.swift
//  todo
//
//  Created by Jack Kroll on 11/25/25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sets: [StudySet]
    @State private var generateSetView: Bool = false
    @State private var searchText: String = ""
    var model = SystemLanguageModel.default
    
    private var filteredSets: [StudySet] {
        if searchText.isEmpty {
            return sets
        }
        return sets.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.setDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if sets.isEmpty {
                    ContentUnavailableView {
                        Label("No Sets Created", systemImage: "square.stack.fill")
                    } description: {
                        Text("Sets you create will appear here.")
                    }
                }
                List {
                    ForEach(filteredSets) { item in
                        NavigationLink(value: item) {
                            GroupBox(item.title) {
                                if let description = item.setDescription {
                                    Text(description)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Text("\(item.cards.count) cards")
                                    if let lastStudied = item.lastStudied {
                                        Text(lastStudied, format: .dateTime)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
            }
            .navigationDestination(for: StudySet.self) { set in
                SetView(set: set)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    if model.isAvailable {
                        Button {
                           generateSetView = true
                        } label: {
                            Image(systemName: "apple.intelligence")
                                .symbolRenderingMode(.multicolor)
                        }
                        .sheet(isPresented: $generateSetView) {
                            GenerateSetView()
                        }
                        
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = StudySet()
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sets[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StudySet.self, inMemory: true)
}
