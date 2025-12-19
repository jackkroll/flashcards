//
//  GenerableCardView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//

import SwiftUI
import Shimmer

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
