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
    @EnvironmentObject var entitlement : EntitlementManager
    @Environment(\.modelContext) var modelContext
    @Bindable var set: StudySet
    @State var isAddCardSheetDisplayed: Bool = false
    @State var genCardSheetDisplayed: Bool = false
    @State var cardViewDislayed: Bool = false
    @State var settingsViewDisplayed: Bool = false
    @State var editCardSheet: Bool = false
    @State private var showPlaySelectionSheet: Bool = false
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
                    List{
                            ForEach(set.cards){ card in
                                CardView(card: card)
                                    .frame(height: 150)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            set.cards.removeAll(where: { $0.id == card.id })
                                            try? modelContext.save()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        NavigationLink(destination: AddCardView(parentSet: set, parentCard: card)) {
                                            Label("Edit", systemImage: "pencil")
                                                .tint(.blue)
                                        }
                                        
                                        
                                    }
                                    .listRowBackground(Color.clear)
                            }
                            .listStyle(.plain)
                            .listRowSeparator(.hidden)
                            
                        
                    }
                    .listStyle(.inset)
                    
                    
                    .frame(maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $isAddCardSheetDisplayed) {
                AddCardView(parentSet: set)
                    //.interactiveDismissDisabled()
            }
            .sheet(isPresented: $genCardSheetDisplayed) {
                GenerableAddCardView(parentSet: set)
                    //.interactiveDismissDisabled()
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
                        
                        Button {
                            withAnimation {
                                settingsViewDisplayed = true
                            }
                        } label: {
                            Image(systemName: "gear")
                        }
                        .sheet(isPresented: $settingsViewDisplayed) {
                            SetSettingsView(studySet: set)
                                .interactiveDismissDisabled()
                                .presentationDetents([.medium, .large])
                        }
                    Spacer()
                    NavigationLink(destination: StatsView(viewingSet: set).environmentObject(entitlement)) {
                        Image(systemName: "chart.bar.fill")
                    }
                    
                    NavigationLink {
                        PlaySelectionView(parentSet: set)
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .disabled(set.cards.isEmpty)
                }
            }
            .navigationTitle(set.title)
            .navigationBarTitleDisplayMode(.inline)
    }
        
}

#Preview {
    let set: StudySet = {
        let s = StudySet()
        for num in 1...20 {
            s.cards.append(Card(front: "Hello \(num.formatted(.number))", back: "World"))
        }
        return s
    }()
    NavigationStack {
        SetView(set: set)
    }
    .environmentObject(EntitlementManager())
}
