//
//  ProFeatureComparison.swift
//  flashcards
//
//  Created by Jack Kroll on 12/21/25.
//

import SwiftUI

// MARK: - Shared Types
enum FeatureAvailability: String {
    case available
    case limited
    case unavailable
}

// MARK: - Icon
private struct AvailabilityIcon: View {
    let status: FeatureAvailability

    var body: some View {
        switch status {
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.green)
        case .limited:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.yellow)
        case .unavailable:
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Column Header
private struct ComparisonHeaderRow: View {
    let columnWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Feature")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Free")
                .frame(width: columnWidth, alignment: .center)
                .foregroundStyle(.secondary)

            Divider()
                .frame(height: 22)

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Pro")
            }
            .fontWeight(.semibold)
            .padding(7)
            .glassEffect()
            .frame(width: columnWidth + 20)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
    }
}

// MARK: - Rows
private struct IndividualRowText: View {
    let featureTitle: String
    let freeHas: String
    let proHas: String
    let columnWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(featureTitle)
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(freeHas)
                .font(.body)
                .frame(width: columnWidth, alignment: .center)

            Divider()
                .frame(height: 22)

            Text(proHas)
                .font(.body)
                .frame(width: columnWidth, alignment: .center)
        }
        .padding(.vertical, 6)
    }
}

private struct IndividualRowAvailable: View {
    let featureTitle: String
    let freeHas: FeatureAvailability
    let proHas: FeatureAvailability
    let columnWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(featureTitle)
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            AvailabilityIcon(status: freeHas)
                .frame(width: 24, height: 24)
                .frame(width: columnWidth, alignment: .center)

            Divider()
                .frame(height: 22)

            AvailabilityIcon(status: proHas)
                .frame(width: 24, height: 24)
                .frame(width: columnWidth, alignment: .center)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Main View
struct ProFeatureComparison: View {
    @EnvironmentObject var entitlement: EntitlementManager
    @EnvironmentObject var router: Router
    @Environment(\.dismiss) var dismiss
    private let columnWidth: CGFloat = 64

    var body: some View {
        List {
            Section {
                ComparisonHeaderRow(columnWidth: columnWidth)

                // Shared features
                IndividualRowAvailable(
                    featureTitle: "Unlimited Saved Sets",
                    freeHas: .available,
                    proHas: .available,
                    columnWidth: columnWidth
                )
                IndividualRowAvailable(
                    featureTitle: "Apple Intelligence Features",
                    freeHas: .available,
                    proHas: .available,
                    columnWidth: columnWidth
                )
                IndividualRowAvailable(
                    featureTitle: "Review as many times as you need",
                    freeHas: .available,
                    proHas: .available,
                    columnWidth: columnWidth
                )

                // Pro differentiators
                IndividualRowAvailable(
                    featureTitle: "Detailed Study Insights",
                    freeHas: .unavailable,
                    proHas: .available,
                    columnWidth: columnWidth
                )
                IndividualRowAvailable(
                    featureTitle: "Works Offline",
                    freeHas: .available,
                    proHas: .available,
                    columnWidth: columnWidth
                )
                IndividualRowAvailable(
                    featureTitle: "Smart Card Recommendations",
                    freeHas: .unavailable,
                    proHas: .available,
                    columnWidth: columnWidth
                )
                IndividualRowAvailable(
                    featureTitle: "Focus on Weak Cards",
                    freeHas: .unavailable,
                    proHas: .available,
                    columnWidth: columnWidth
                )
                Button{
                    router.push(.storeView)
                } label: {
                        Image(systemName: "sparkles")
                        Text("Upgrade to Pro")
                            .fontWeight(.semibold)
                }
                .buttonSizing(.flexible)
                .buttonStyle(.glassProminent)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Core features will **always** remain free for all. A pro plan supports development, while also giving you insights to support your studying.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    
                }
                .padding(.top, 4)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            if entitlement.hasPro {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProFeatureComparison()
    }
    .environmentObject(EntitlementManager())
    .environmentObject(Router())
}
