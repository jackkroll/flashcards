//
//  InfoCard.swift
//  flashcards
//
//  A simple, reusable container view that mimics Health app style info cards.
//

import SwiftUI

struct InfoCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Spacer()
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            InfoCard(title: "Sample Card", subtitle: "Subtitle") {
                Text("This is where your content goes.")
            }
            InfoCard(title: "Another Card") {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Charts and stats look great here.")
                }
            }
        }
        .padding()
    }
}
