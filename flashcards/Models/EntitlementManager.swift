//
//  TransactionObserver.swift
//  flashcards
//
//  Created by Jack Kroll on 12/19/25.
//

import Foundation
import StoreKit
import Combine

@MainActor
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()
    static let productIDs = ["pro.monthly", "pro.family.monthly", "pro.yearly"]
    @Published var hasPro: Bool = false
    
    init(){
        Task {
            await refreshEntitlements()
            await listenForTransactions()
        }
    }
    
    @MainActor
    private func refreshEntitlements() async {
        hasPro = await hasActivePro()
    }
    
    @MainActor
    private func listenForTransactions() async {
        for await _ in Transaction.updates {
            await refreshEntitlements()
        }
    }
    
    @MainActor
    private func hasActivePro() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if EntitlementManager.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }
    
    
    
}
