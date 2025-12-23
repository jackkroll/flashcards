//
//  StreakView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/21/25.
//

import SwiftUI

struct StreakToolbarItem: ToolbarContent {
    @AppStorage("lastStudyDate") private var lastStudyDate: Date = .distantPast
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    let placement: ToolbarItemPlacement
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: placement){
            Image(systemName: isOverdue() ? "flame" : "flame.fill")
                .foregroundStyle(isOverdue() ? Color.gray.gradient : Color.orange.gradient)
            if currentStreak > 0 {
                Text("\(currentStreak)")
                .bold()
                .monospaced()
            }
        }
    }
    
    func isOverdue() -> Bool {
        if lastStudyDate.distance(to: .now) > 1.toDays {
            currentStreak = 0
            return true
        }
        else {
            return false
        }
    }
}

extension Double {
    var toMinutes: TimeInterval { return self * 60.0 }
    var toHours: TimeInterval { return self.toMinutes * 60.0 }
    var toDays: TimeInterval { return self.toHours * 24}
}

#Preview {
    NavigationStack {
        VStack {
            Text("Hello World")
                
        }
        .toolbar {
            StreakToolbarItem(placement: .topBarLeading)
        }
    }
}
