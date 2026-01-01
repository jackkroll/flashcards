//
//  CardView.swift
//  todo
//
//  Created by Jack Kroll on 12/12/25.
//

import SwiftUI
import Shimmer

struct CardView: View {
    @EnvironmentObject var entitlement: EntitlementManager
    @AppStorage("strongMinPercentCorrectEnabled") private var strongMinPercentCorrectEnabled: Bool = true
    @AppStorage("strongMinPercentCorrect") private var strongMinPercentCorrect: Double = 0.8
    @AppStorage("strongMaxTimeToFlipEnabled") private var strongMaxTimeToFlipEnabled: Bool = false
    @AppStorage("strongMaxTimeToFlipSeconds") private var strongMaxTimeToFlipSeconds: Double = 5
    @AppStorage("strongRecallWindow") private var strongRecallWindow: Int = 10

    @AppStorage("weakMaxPercentCorrectEnabled") private var weakMaxPercentCorrectEnabled: Bool = true
    @AppStorage("weakMaxPercentCorrect") private var weakMaxPercentCorrect: Double = 0.4
    @AppStorage("weakMinTimeToFlipEnabled") private var weakMinTimeToFlipEnabled: Bool = false
    @AppStorage("weakMinTimeToFlipSeconds") private var weakMinTimeToFlipSeconds: Double = 7
    @AppStorage("weakRecallWindow") private var weakRecallWindow: Int = 10
    
    @State private var currentSide = side.A
    @State var card: Card? = nil
    
    var body: some View {
        ConcentricRectangle(corners: .concentric(minimum: 50), isUniform: true)
            .foregroundStyle(.background.secondary)
            .overlay {
                ZStack {
                    if let card = card {
                        CardContentView(side: card.front)
                            .opacity(currentSide == .A ? 1 :0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        CardContentView(side: card.back)
                            .opacity(currentSide == .B ? 1 :0)
                            .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: -1.0, z: 0.0))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else {
                        VStack {
                            Text("Placeholder Text")
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 30)
                .padding(20)
                .font(.system(size: 60))
                .minimumScaleFactor(0.003)
                .frame(minWidth: 50, idealWidth: 100, maxWidth: .infinity)
                .overlay {
                    VStack {
                        Spacer()
                        HStack {
                            Text(currentSide == .A ? "FRONT" : "BACK")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .fontDesign(.monospaced)
                                .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: currentSide == .A ? 0 : -1.0, z: 0.0))
                            Spacer()
                            if let card = card {
                                if entitlement.hasPro {
                                    if card.determineIfStrong(
                                        minPercentCorrect: strongMinPercentCorrectEnabled ? strongMinPercentCorrect : nil,
                                        maxTimeToFlip: strongMaxTimeToFlipEnabled ? strongMaxTimeToFlipSeconds : nil,
                                        recallWindow: strongRecallWindow) {
                                        Text("STRONG CARD")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .fontDesign(.monospaced)
                                            .shimmering()
                                            .brightness(2)
                                            .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: currentSide == .A ? 0 : -1.0, z: 0.0))
                                    }
                                    else if card.determineIfWeak(
                                        maxPercentCorrect: weakMaxPercentCorrectEnabled ? weakMaxPercentCorrect : nil,
                                        minTimeToFlip: weakMinTimeToFlipEnabled ? weakMinTimeToFlipSeconds : nil,
                                        recallWindow: weakRecallWindow) {
                                        Text("WEAK CARD")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .fontDesign(.monospaced)
                                            .shimmering()
                                            .brightness(2)
                                            .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: currentSide == .A ? 0 : -1.0, z: 0.0))
                                    }
                                }
                            }
                        }
                        .foregroundStyle(.tertiary)
                        .padding([.horizontal, .bottom], 30)
                    }
                }
                
            }
            .rotation3DEffect(.degrees(currentSide == .A ? 0 : 180), axis: (x: 0.0, y: 1.0, z: 0.0))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.5)){
                    switch currentSide {
                    case .A:
                        currentSide = .B
                    case .B:
                        currentSide = .A
                    }
                }
            }
            .disabled(card == nil)
    }
    private enum side {
        case A,B
    }
}

struct CardContentView : View {
    @Environment(\.colorScheme) var colorScheme
    @State var side : SingleSide
    var body: some View {
        switch side.sideType {
        case .text:
            Text(side.text ?? "No content")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .fontDesign(.rounded)
                .allowsTightening(true)
        case .image:
            if let imageData = side.img {
                if let uiImg = UIImage(data: imageData) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                        .clipped(antialiased: true)
                        .clipShape(ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true))
                }
            }
        case .audio:
            Text("Audio Implementation")
        }
    }
}

#Preview("Card Added"){
    VStack {
        CardView(card: Card(front: "Front Side", back: "Back Side"))
        CardView(card: Card(front: "Front Side", back: "Back Side"))
            .frame(height: 200)
    }
    .environmentObject(EntitlementManager())
}
#Preview("Image Card") {
    let card = Card(front: SingleSide(img: Image(systemName: "apple.logo")), back: SingleSide(img: Image(systemName: "apple.logo")))
    VStack {
        CardView(card: card)
        CardView(card: card)
            .frame(height: 200)
    }
    .environmentObject(EntitlementManager())
}
#Preview("No Card"){
    VStack {
        CardView(card: nil)
        CardView(card: nil)
            .frame(height: 200)
    }
    .environmentObject(EntitlementManager())
}
