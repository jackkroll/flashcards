//
//  MeshBackground.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//
import SwiftUI

struct MeshBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
                SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
                SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
            ],
            colors: meshColors
        )
        .ignoresSafeArea()
    }

    private var meshColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(.systemBackground), Color(.secondarySystemBackground), Color(.systemBackground),
                Color(.secondarySystemBackground), Color(.tertiarySystemBackground), Color(.secondarySystemBackground),
                Color(.systemBackground), Color(.secondarySystemBackground), Color(.systemBackground)
            ]
        } else {
            return [
                Color(white: 0.96), Color(white: 0.8), Color(white: 0.96),
                Color(white: 0.8), Color(white: 0.5), Color(white: 0.8),
                Color(white: 0.96), Color(white: 0.8), Color(white: 0.96)
            ]
        }
    }
}

#Preview {
    MeshBackground()
}
