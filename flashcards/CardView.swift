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
    var body: some View {
        RoundedRectangle(cornerRadius: 50)
            .foregroundStyle(.background.secondary)
            .overlay {
                ZStack {
                    if let card = card {
                        CardContentView(side: card.front)
                            .opacity(currentSide == .A ? 1 :0)
                        CardContentView(side: card.back)
                            .opacity(currentSide == .B ? 1 :0)
                            .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: -1.0, z: 0.0))
                    }
                    else {
                        VStack {
                            Text("Placeholder Text")
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
                .font(.system(size: 60))
                .minimumScaleFactor(0.003)
                .frame(minWidth: 50, idealWidth: 100, maxWidth: .infinity)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Text(currentSide == .A ? "FRONT" : "BACK")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: currentSide == .A ? 0 : -1.0, z: 0.0))
                        Spacer()
                    }
                    .foregroundStyle(.tertiary)
                    .padding([.horizontal, .bottom], 30)
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

struct GenerableCardView: View {
    @State private var currentSide = side.A
    var card: GenerableCard.PartiallyGenerated
    var body: some View {
        RoundedRectangle(cornerRadius: 50)
            .foregroundStyle(.background.secondary)
            .overlay {
                ZStack {
                    Text(card.front == nil || card.front!.isEmpty ? "No Content" : card.front!)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .fontDesign(.rounded)
                            .opacity(currentSide == .A ? 1 :0)
                            .redacted(reason: card.front == nil || card.front!.isEmpty ? .placeholder : [])
                            .shimmering(active: card.front == nil || card.front!.isEmpty)
                    Text(card.back == nil || card.back!.isEmpty ? "No Content" : card.back!)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .fontDesign(.rounded)
                            .opacity(currentSide == .B ? 1 :0)
                            .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: -1.0, z: 0.0))
                            .redacted(reason: card.back == nil || card.back!.isEmpty ? .placeholder : [])
                            .shimmering(active: card.back == nil || card.back!.isEmpty)
                }
                .padding(20)
                .font(.system(size: 60))
                .minimumScaleFactor(0.003)
                .frame(minWidth: 50, idealWidth: 100, maxWidth: .infinity)
                
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
}
#Preview("No Card"){
    CardView(card: nil)
}
