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
    @EnvironmentObject var entitlement: EntitlementManager
    @Query private var sets: [StudySet]
    @State private var generateSetView: Bool = false
    @State private var searchText: String = ""
    @State private var createSetView: Bool = false
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
                        Label("NO SETS CREATED".lowercased(), systemImage: "square.stack.fill")
                            .fontDesign(.monospaced)
                    } description: {
                        Text("sets you create will appear here")
                            .fontDesign(.monospaced)
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
                
            }
            .navigationDestination(for: StudySet.self) { set in
                SetView(set: set)
            }
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("RECALL")
                        .fontWeight(.semibold)
                        .font(.title3)
                        .fontDesign(.monospaced)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(.secondary)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem {
                    Button {
                        createSetView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $createSetView) {
                        SetSettingsView(studySet: nil)
                            .presentationDetents([.medium, .large])
                            //.interactiveDismissDisabled()
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
                
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                        }
                }
            }
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
