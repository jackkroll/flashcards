//
//  todoApp.swift
//  todo
//
//  Created by Jack Kroll on 11/25/25.
//

import SwiftUI
import SwiftData

@main
struct todoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudySet.self, Card.self, SingleSide.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
