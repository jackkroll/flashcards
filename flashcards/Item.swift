//
//  Item.swift
//  todo
//
//  Created by Jack Kroll on 11/25/25.
//

import Foundation
import SwiftData
import SwiftUI
import FoundationModels

@Model
final class StudySet {
    var title: String
    var setDescription: String?
    var created: Date
    var lastStudied: Date? = nil
    var stats: SetStats? = nil
    @Relationship(inverse: \Card.setMembership) var cards: [Card] = []
    
    init() {
        self.title = "Untitled"
        self.setDescription = nil
        self.created = .now
        self.stats = SetStats()
    }
    func setTextualRepresentation() -> String {
        var representation = "Name: \(title)\nDescription: \(setDescription ?? "No description")\n"
        if cards.isEmpty {
            return "This study set is empty."
        }
        else {
            
            for card in cards {
                representation.append("\(card.front.text ?? "No textual representation") -> \(card.back.text ?? "No textual represetation")\n")
            }
            return representation
        }
    }
}
@Model
final class CardStats {
    var timeToFlip: [TimeInterval]
    var gottenCorrect: [Bool]
    
    init() {
        self.timeToFlip = []
        self.gottenCorrect = []
    }
    
    func addGottenCorrect(_ correct: Bool) {
        gottenCorrect.append(correct)
        while gottenCorrect.count > 10 {
            gottenCorrect.removeFirst()
        }
    }
    
    func addTimeToFlip(_ time: TimeInterval) {
        timeToFlip.append(time)
        while timeToFlip.count > 10 {
            timeToFlip.removeFirst()
        }
    }
    
    func rollingPercentCorrect() -> Double {
        let correctCount = gottenCorrect.filter(\.self).count
        return Double(correctCount) / Double(gottenCorrect.count)
    }
    
    func avgTimeToFlip() -> TimeInterval {
        return timeToFlip.reduce(0, +) / TimeInterval(timeToFlip.count)
    }
}

@Model
final class SetStats {
    var totalStudyTime: TimeInterval
    
    init() {
        self.totalStudyTime = 0
    }
}



@Model
final class Card {
    @Relationship var setMembership : StudySet? = nil
    var front: SingleSide
    var back: SingleSide
    var stats: CardStats? = nil
    
    init(front: SingleSide, back: SingleSide) {
        self.front = front
        self.back = back
        self.stats = CardStats()
    }
    
    init(front: String, back: String) {
        self.front = SingleSide(text: front)
        self.back = SingleSide(text: back)
        self.stats = CardStats()
    }
}

@Model
final class SingleSide {
    enum SideType: String, Codable, CaseIterable{
        case text, image, audio
    }
    
    var sideType: SideType = SideType.text
    var text: String?
    var img: Data?
    
    func fetchImage() -> Image? {
        if let img = img {
            return Image.from(data: img)
        } else {
            return nil
        }
    }
    
    @MainActor
    init(img: Image) {
        self.img = ImageRenderer(content: img).uiImage?.pngData()
        self.sideType = .image
    }
    
    init(img: Data) {
        self.img = img
        self.sideType = .image
    }
    
    init(text: String) {
        self.text = text
        self.sideType = .text
    }
    
}

@Generable
struct GenerableSet {
    var title: String
    var description: String?
    @Guide(description: "The flashcards of the set, following the provided theme", .minimumCount(5))
    var cards: [GenerableCard]
    
    func exportToStudySet() -> StudySet {
        let studySet = StudySet()
        studySet.title = title
        studySet.setDescription = description
        studySet.cards = cards.map{ genCard in
            return Card(front: genCard.front, back: genCard.back)
        }
        return studySet
    }
}

@Generable
struct GenerableCard {
    @Guide(description: "The front of a flashcard, often a question following the form of 'who, what, where, when, why, how', or a proposition that can either be true or false")
    var front: String
    @Guide(description: "The back of a flashcard, the answer to the question on the front of the card, which is a short statement or simply 'true/false' depending on the question")
    var back: String
    
    func asCard() -> Card {
        return Card(front: front, back: back)
    }
}

extension Image {
    /// Creates a SwiftUI `Image` from data.
    static func from(data: Data) -> Image? {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        } else {
            return nil
        }
        #else
        return nil
        #endif
    }
}
