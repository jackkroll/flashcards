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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var entitlement: EntitlementManager
    @EnvironmentObject var router: Router
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
        NavigationStack(path: $router.path){
            VStack {
                if sets.isEmpty {
                    ContentUnavailableView {
                        Label("No Sets Created", systemImage: "square.stack.fill")
                    } description: {
                        Text("Sets you create will appear here")
                    }
                }
                List {
                    ForEach(filteredSets) { item in
                        NavigationLink(value: Route.set(setID: item.persistentModelID)) {
                            GroupBox(item.title) {
                                if let description = item.setDescription {
                                    Text(description)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Text("\(item.cards.count) cards")
                                    if let lastStudied = item.lastStudied {
                                        Spacer()
                                        Text("Studied: ")
                                        Text(lastStudied.formatted(date: .abbreviated, time: .omitted))
                                    }
                                    else {
                                        Spacer()
                                    }
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
            .navigationDestination(for: Route.self) { route in
                RouterViewDestination(route: route)
            }
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 0){
                        Text("RECALL")
                            .fontWeight(.semibold)
                            .font(.title3)
                            .fontDesign(.monospaced)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(.secondary)
                        if entitlement.hasPro {
                            Text(":PRO")
                                .fontWeight(.semibold)
                                .font(.title3)
                                .fontDesign(.monospaced)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .sharedBackgroundVisibility(.hidden)
                StreakToolbarItem(placement: .topBarLeading)
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
                    if model.isAvailable && model.supportsLocale(){
                        Button {
                           generateSetView = true
                        } label: {
                            Image(systemName: "apple.intelligence")
                                .symbolRenderingMode(.multicolor)
                        }
                        .sheet(isPresented: $generateSetView) {
                            NavigationStack {
                                GenerateSetView()
                            }
                        }
                        
                    }
                }
                
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        router.push(.settings)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onOpenURL(perform: handleURL)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sets[index])
            }
        }
    }
    
    func handleURL(url: URL) {
        print("handling URL \(url.absoluteString)")
        guard url.scheme == "recallapp" else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }

        guard let action = components.host, action == "open-set" else {
            print("Unknown URL, we can't handle this one!")
            return
        }

        guard let setTitle = components.queryItems?.first(where: { $0.name == "setTitle" })?.value else {
            print("Set not found")
            return
        }
        guard let selectedSetID = sets.first(where: {$0.title.elementsEqual(setTitle)}) else { return }
        router.push(.set(setID: selectedSetID.persistentModelID))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StudySet.self, inMemory: true)
        .environmentObject(EntitlementManager())
        .environmentObject(Router())
}

