//
//  WeakStrongSettings.swift
//  flashcards
//
//  Created by Jack Kroll on 12/27/25.
//

import SwiftUI

struct WeakStrongSettings: View {
    @AppStorage("strongMinPercentCorrectEnabled",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var strongMinPercentCorrectEnabled: Bool = true
    @AppStorage("strongMinPercentCorrect",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var strongMinPercentCorrect: Double = 0.8
    @AppStorage("strongMaxTimeToFlipEnabled",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var strongMaxTimeToFlipEnabled: Bool = false
    @AppStorage("strongMaxTimeToFlipSeconds",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var strongMaxTimeToFlipSeconds: Double = 5
    @AppStorage("strongRecallWindow",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var strongRecallWindow: Int = 10

    @AppStorage("weakMaxPercentCorrectEnabled",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var weakMaxPercentCorrectEnabled: Bool = true
    @AppStorage("weakMaxPercentCorrect",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var weakMaxPercentCorrect: Double = 0.4
    @AppStorage("weakMinTimeToFlipEnabled",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var weakMinTimeToFlipEnabled: Bool = false
    @AppStorage("weakMinTimeToFlipSeconds",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var weakMinTimeToFlipSeconds: Double = 7
    @AppStorage("weakRecallWindow",
                store: UserDefaults(suiteName: "group.JackKroll.recall")) private var weakRecallWindow: Int = 10
    
    // Shows the footer only when at least one toggle is currently disabled
    private var anyToggleDisabled: Bool {
        (strongMinPercentCorrectEnabled && !strongMaxTimeToFlipEnabled) ||
        (strongMaxTimeToFlipEnabled && !strongMinPercentCorrectEnabled) ||
        (weakMaxPercentCorrectEnabled && !weakMinTimeToFlipEnabled) ||
        (weakMinTimeToFlipEnabled && !weakMaxPercentCorrectEnabled)
    }
    
    var body: some View {
        VStack {
            Form {
                Section("Strong Cards Threshold Calculation") {
                    VStack(alignment: .leading) {
                        Toggle("Min percent correct", isOn: $strongMinPercentCorrectEnabled)
                            .disabled(strongMinPercentCorrectEnabled && !strongMaxTimeToFlipEnabled)
                        Text("Cards considered strong should have a minimum percentage correct")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if strongMinPercentCorrectEnabled {
                        VStack(alignment: .leading) {
                            HStack {
                                Slider(value: $strongMinPercentCorrect, in: 0...1, step: 0.01)
                                Text("\(strongMinPercentCorrect, format: .percent)")
                            }
                        }
                    }
                    
                    VStack(alignment: .leading ) {
                        Toggle("Max time to complete", isOn: $strongMaxTimeToFlipEnabled)
                            .disabled(strongMaxTimeToFlipEnabled && !strongMinPercentCorrectEnabled)
                        Text("Cards considered strong should be completed in under a certain amount of time")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if strongMaxTimeToFlipEnabled {
                        Stepper(value: $strongMaxTimeToFlipSeconds, in: 0...600, step: 1) {
                            Text("\(Int(strongMaxTimeToFlipSeconds)) seconds")
                        }
                    }
                    VStack(alignment: .leading ) {
                        Stepper(value: $strongRecallWindow, in: 1...100, step: 1) {
                            HStack {
                                Text("Recall Window")
                                Spacer()
                                Text("\(strongRecallWindow)")
                            }
                            
                        }
                        Text("Maximum # of study times to consider")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Weak Cards Threshold Calculation") {
                    VStack(alignment: .leading) {
                        Toggle("Max percent correct", isOn: $weakMaxPercentCorrectEnabled)
                            .disabled(weakMaxPercentCorrectEnabled && !weakMinTimeToFlipEnabled)
                        Text("Cards considered weak should have a maximum percentage correct")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if weakMaxPercentCorrectEnabled {
                        VStack(alignment: .leading) {
                            HStack {
                                Slider(value: $weakMaxPercentCorrect, in: 0...1, step: 0.01)
                                Text("\(weakMaxPercentCorrect, format: .percent)")
                            }
                        }
                    }
                    
                    VStack(alignment: .leading ) {
                        Toggle("Min time to complete", isOn: $weakMinTimeToFlipEnabled)
                            .disabled(weakMinTimeToFlipEnabled && !weakMaxPercentCorrectEnabled)
                        Text("Cards considered weak should be completed in over a certain amount of time")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if weakMinTimeToFlipEnabled {
                        Stepper(value: $weakMinTimeToFlipSeconds, in: 0...600, step: 1) {
                            Text("\(Int(weakMinTimeToFlipSeconds)) seconds")
                        }
                    }
                    
                    VStack(alignment: .leading ) {
                        Stepper(value: $weakRecallWindow, in: 1...100, step: 1) {
                            HStack {
                                Text("Recall Window")
                                Spacer()
                                Text("\(weakRecallWindow)")
                            }
                        }
                        Text("Maximum # of study times to consider")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    if anyToggleDisabled {
                        Text("Calculation must have at least one criteria selected")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .background(.clear)
                            .padding()
                            .glassEffect()
                            .padding()
                        
                    }
                }
                .animation(.easeInOut, value: anyToggleDisabled)
            }
        }
    }
}

#Preview {
    WeakStrongSettings()
}
