//
//  SettingsView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//

import SwiftUI
import StoreKit
import SwiftData
import WidgetKit

struct SettingsView: View {
    @AppStorage("lastStudyDate",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var lastStudyDate: Date = .distantPast
    @AppStorage("currentStreak",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var currentStreak: Int = 0
    @EnvironmentObject var entitlement: EntitlementManager
    @Environment(\.modelContext) var modelContext
    @State private var deleteAllDataAlertIsPresented: Bool = false
    @State private var deleteAllStatsAlertIsPresented: Bool = false
    
    var body: some View {
        VStack {
            Form {
                
                Section {
                    NavigationLink {
                        WeakStrongSettings()
                    } label: {
                        Text("Card Calculation Settings")
                    }
                    
                    Button("Restore Purchases") {
                        Task {
                            try await AppStore.sync()
                        }
                    }
                } header: {
                  Text("Pro Settings")
                } footer: {
                    if !entitlement.hasPro {
                        Text("Though you are not a Recall: PRO subscriber, you can adjust these settings, which will change your PRO recomendations and will apply if you subscribe.")
                    }
                }
                
                Section("Manage On-Device data"){
                    Button(role: .destructive) {
                        deleteAllDataAlertIsPresented = true
                    } label: {
                        Text("Delete all stored data")
                    }
                    .alert(
                        "Are you sure?",
                        isPresented: $deleteAllDataAlertIsPresented,
                    ) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    let descriptor = FetchDescriptor<StudySet>()
                                    let allSets = try modelContext.fetch(descriptor)
                                    for set in allSets {
                                        modelContext.delete(set)
                                    }
                                    try modelContext.save()
                                } catch {
                                    
                                }
                            }
                        } label: {
                            Text("Delete")
                        }
                    } message: {
                        Text("""
                             This will permenently delete
                             - All sets
                             - All associated cards
                             - All associated stats 
                             """)
                    }
                    /*
                    Button(role: .destructive) {
                        deleteAllStatsAlertIsPresented = true
                    } label: {
                        Text("Delete all stored stats")
                    }
                    .alert(
                        "Are you sure?",
                        isPresented: $deleteAllStatsAlertIsPresented,
                    ) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    let descriptor = FetchDescriptor<CardStats>()
                                    let allStats = try modelContext.fetch(descriptor)
                                    for set in allStats {
                                        modelContext.delete(set)
                                    }
                                    try modelContext.save()
                                    
                                    let descriptorSet = FetchDescriptor<SetStats>()
                                    let allStatsSet = try modelContext.fetch(descriptorSet)
                                    for set in allStatsSet {
                                        modelContext.delete(set)
                                    }
                                    try modelContext.save()
                                } catch {
                                    
                                }
                            }
                        } label: {
                            Text("Delete")
                        }
                    } message: {
                        Text("""
                             This will remove all stats for every set and individual cards\n
                             For pro users, the removal of all stats will result in the data pages being blank until more stats are collected.
                             """)
                    }
                     */
                }
                /*
                Section("Developer") {
                    
                    Button("Add Demo Sets") {
                        addDemoSets()
                        WidgetCenter.shared.reloadTimelines(ofKind: "JumpInWidget")
                    }
                    
                    Button("Update Streak") {
                        lastStudyDate = .now
                        currentStreak = 2
                        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
                    }
                    
                    Button("Reset Streak") {
                        lastStudyDate = .distantPast
                        currentStreak = 0
                        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
                    }
                }
                 */
                
            }

        }
        .navigationTitle("Settings")
    }
}

extension SettingsView {
    private func addDemoSets() {
        do {
            // Avoid duplicating demo sets if they already exist by title
            let existing = try modelContext.fetch(FetchDescriptor<StudySet>())
            let existingTitles = Set(existing.map { $0.title })

            let demoData: [(title: String, description: String?, pairs: [(String, String)])] = [
                (
                    title: "US State Capitals (Sample)",
                    description: "Ten well-known states and their capitals.",
                    pairs: [
                        ("California", "Sacramento"),
                        ("Texas", "Austin"),
                        ("New York", "Albany"),
                        ("Florida", "Tallahassee"),
                        ("Illinois", "Springfield"),
                        ("Washington", "Olympia"),
                        ("Colorado", "Denver"),
                        ("Massachusetts", "Boston"),
                        ("Georgia", "Atlanta"),
                        ("Arizona", "Phoenix")
                    ]
                ),
                (
                    title: "Spanish Basics: Common Phrases (Sample)",
                    description: "Everyday phrases for beginners.",
                    pairs: [
                        ("Hola", "Hello"),
                        ("Gracias", "Thank you"),
                        ("Por favor", "Please"),
                        ("¿Cómo estás?", "How are you?"),
                        ("Bien", "Good"),
                        ("Lo siento", "I'm sorry"),
                        ("¿Dónde está el baño?", "Where is the bathroom?"),
                        ("Me llamo…", "My name is…"),
                        ("Buenos días", "Good morning"),
                        ("Buenas noches", "Good night")
                    ]
                ),
                (
                    title: "Biology: Cell Organelles (Sample)",
                    description: "Key organelles and their functions.",
                    pairs: [
                        ("Mitochondria", "Powerhouse of the cell; produces ATP"),
                        ("Nucleus", "Contains genetic material (DNA)"),
                        ("Ribosome", "Site of protein synthesis"),
                        ("Rough ER", "Protein processing and transport"),
                        ("Smooth ER", "Lipid synthesis and detoxification"),
                        ("Golgi apparatus", "Modifies, sorts, packages proteins"),
                        ("Lysosome", "Contains digestive enzymes"),
                        ("Cell membrane", "Selective barrier; regulates entry/exit"),
                        ("Chloroplast", "Photosynthesis (plants)"),
                        ("Vacuole", "Storage; turgor pressure (plants)")
                    ]
                )
            ]

            var createdAny = false

            for demo in demoData {
                if existingTitles.contains(demo.title) { continue }

                let set = StudySet(title: demo.title, description: demo.description)
                for (front, back) in demo.pairs {
                    let card = Card(front: front, back: back)
                    set.cards.append(card)
                }

                // Simulate realistic stats so strong/weak logic has data
                for (idx, card) in set.cards.enumerated() {
                    // Create a mix: early cards strong, middle average, some weak
                    let bucket = idx % 5
                    switch bucket {
                    case 0, 1:
                        simulateStats(for: card, correctProbability: 0.9, timeRange: 2.0...4.5, count: Int.random(in: 22...32))
                    case 2, 3:
                        simulateStats(for: card, correctProbability: 0.6, timeRange: 4.0...7.0, count: Int.random(in: 20...28))
                    default:
                        simulateStats(for: card, correctProbability: 0.35, timeRange: 7.0...12.0, count: Int.random(in: 18...26))
                    }
                }

                // Set-level stats
                set.stats.totalStudyTime = Double.random(in: 600...3600) // 10 min to 1 hr
                set.lastStudied = Date().addingTimeInterval(-Double.random(in: 0...(60*60*24*7))) // within last week

                modelContext.insert(set)
                createdAny = true
            }

            if createdAny {
                try? modelContext.save()
            }
        } catch {
            // Ignore errors for demo seeding in previews
        }
    }

    private func simulateStats(for card: Card, correctProbability: Double, timeRange: ClosedRange<Double>, count: Int) {
        for _ in 0..<count {
            let gotCorrect = Double.random(in: 0...1) < correctProbability
            let time = Double.random(in: timeRange)
            let secondsAgo = Double.random(in: 0...(60*60*24*30)) // spread over last 30 days
            let when = Date().addingTimeInterval(-secondsAgo)
            card.stats.record(timeToFlip: time, gotCorrect: gotCorrect, timeCompleted: when)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(EntitlementManager())
}

