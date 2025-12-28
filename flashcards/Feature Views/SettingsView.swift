//
//  SettingsView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var entitlement: EntitlementManager
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
                            // Handle the deletion.
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
                            // Handle the deletion.
                        } label: {
                            Text("Delete")
                        }
                    } message: {
                        Text("""
                             This will remove all stats for every set and individual cards\n
                             For pro users, the removal of all stats will result in the data pages being blank until more stats are collected.
                             """)
                    }
                }
                
            }

        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(EntitlementManager())
}
