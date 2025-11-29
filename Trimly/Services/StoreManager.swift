import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class StoreManager: ObservableObject {
    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    
    private let productIds = ["trimtallypro"]
    private var updates: Task<Void, Never>? = nil
    
    init() {
        updates = newTransactionListenerTask()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    func requestProducts() async {
        do {
            let products = try await Product.products(for: productIds)
            self.products = products
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restore() async {
        try? await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    func updateCustomerProductStatus() async {
        var purchasedPro = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == "trimtallypro" {
                    purchasedPro = true
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        self.isPro = purchasedPro
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
