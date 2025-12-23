//
//  CardView.swift
//  todo
//
//  Created by Jack Kroll on 12/12/25.
//

import SwiftUI
import Shimmer

struct CardView: View {
    @State private var currentSide = side.A
    @State var card: Card? = nil
    @EnvironmentObject var entitlement: EntitlementManager
    let minPercentCorrect: Double = 90
    let maxTimeToFlip: TimeInterval? = nil
    
    let maxPercentCorrect: Double = 60
    let minTimeToFlip: TimeInterval? = nil
    
    let recallWindow: Int = 10
    var body: some View {
        RoundedRectangle(cornerRadius: 50)
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
                                    if card.determineIfStrong(minPercentCorrect: minPercentCorrect, maxTimeToFlip: maxTimeToFlip, recallWindow: recallWindow) {
                                        Text("WEAK CARD")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .fontDesign(.monospaced)
                                            .shimmering()
                                            .brightness(2)
                                    }
                                    else if card.determineIfWeak(maxPercentCorrect: maxPercentCorrect, minTimeToFlip: minTimeToFlip, recallWindow: recallWindow) {
                                        Text("STRONG CARD")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .fontDesign(.monospaced)
                                            .shimmering()
                                            .brightness(2)
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
                        .padding()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        case .audio:
            Text("Audio Implementation")
        }
    }
}

#Preview("Card Added"){
    CardView(card: Card(front: "Front Side", back: "Back Side"))
        .environmentObject(EntitlementManager())
}
#Preview("No Card"){
    CardView(card: nil)
        .environmentObject(EntitlementManager())
}
