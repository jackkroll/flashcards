//
//  StoreView.swift
//  flashcards
//
//  Created by Jack Kroll on 12/18/25.
//

import SwiftUI
import SwiftData
import StoreKit
import Shimmer

struct StoreView: View {
    @EnvironmentObject var entitlement: EntitlementManager
    @EnvironmentObject var router: Router
    var body: some View {
            SubscriptionStoreView(groupID: "21863675") {
                VStack {
                    HStack {
                        let title: AttributedString = {
                            var a = AttributedString("RECALL:PRO")
                            if let range = a.range(of: "PRO") {
                                a[range].foregroundColor = .secondary
                            }
                            return a
                        }()
                        Text(title)
                            .fontDesign(.monospaced)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    
                    Text("""
                        Access insights into your studying.
                        Understand what to keep, what to remove, and what to review next.
                        """)
                    .minimumScaleFactor(0.05)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                }
                .containerBackground(for: .subscriptionStoreFullHeight) {
                    MeshBackground()
                }
                
            }
            .backgroundStyle(.thinMaterial)
            .navigationBarBackButtonHidden()
            .onChange(of: entitlement.hasPro) { old, new in
                if new {
                    let id = router.popToLast(case: .set)
                    if let id = id {
                        router.push(.stats(setID: id))
                    }
                }

            }
        }
}

#Preview {
    StoreView()
        .environmentObject(EntitlementManager())
}
