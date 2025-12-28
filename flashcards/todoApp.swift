//
//  todoApp.swift
//  todo
//
//  Created by Jack Kroll on 11/25/25.
//

import SwiftUI
import SwiftData
import Onboarding

@main
struct todoApp: App {
    @StateObject var entitlement = EntitlementManager()
    @StateObject var router = Router()
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
                .environmentObject(entitlement)
                .environmentObject(router)
                .showOnboardingIfNeeded { markComplete in
                    WelcomeScreen.modern(
                        accentColor: .orange,
                        appDisplayName: "Recall",
                        appIcon: Image("AppIcon"),
                        features: [
                            FeatureInfo(
                                image: Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill"),
                                title: "Study on your terms",
                                content: "No interuptions, no nagging, focus only on your studying"
                            ),
                            FeatureInfo(
                                image: Image(systemName: "wifi.slash"),
                                title: "No connection? No problem",
                                content: "All of your data is exclusively stored on device, giving you full control when offline"
                            )
                        ],
                        termsOfServiceURL: URL(string: "https://jackk.dev/projects/recall/terms/")!,
                        privacyPolicyURL: URL(string: "https://jackk.dev/projects/recall/prvacy/")!
                    ).with(continueAction: {
                       markComplete()
                    })
                
                }
        }
        .modelContainer(sharedModelContainer)
        
    }
}

