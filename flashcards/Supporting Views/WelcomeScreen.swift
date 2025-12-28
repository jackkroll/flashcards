//
//  WelcomeScreen.swift
//  flashcards
//
//  Created by Jack Kroll on 12/24/25.
//


import Onboarding
import SwiftUI

extension WelcomeScreen {
    static let production = WelcomeScreen.modern(
        accentColor: .blue,
        appDisplayName: "My Amazing App",
        appIcon: Image("AppIcon"),
        features: [
            FeatureInfo(
                image: Image(systemName: "star.fill"),
                title: "Amazing Features",
                content: "Discover powerful tools that make your life easier."
            ),
            FeatureInfo(
                image: Image(systemName: "shield.fill"),
                title: "Privacy First",
                content: "Your data stays private and secure on your device."
            ),
            FeatureInfo(
                image: Image(systemName: "bolt.fill"),
                title: "Lightning Fast",
                content: "Optimized performance for the best user experience."
            )
        ],
        termsofServiceURL: URL(string: "https://jackk.dev/projects/recall/terms/"),
        privacyPolicyURL: URL(string: "https://jackk.dev/projects/recall/privacy/"),
        titleSectionAlignment: .center
    )
}
