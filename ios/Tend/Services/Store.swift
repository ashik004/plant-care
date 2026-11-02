import StoreKit
import Observation

/// StoreKit 2: a non-consumable for Lifetime and an auto-renewable subscription with a
/// 7-day free trial for Monthly. Prices come from `Product.displayPrice`; the strings
/// below are only shown before products load (and in previews).
@MainActor
@Observable
final class Store {
    static let lifetimeID = "app.tend.premium.lifetime"
    static let monthlyID = "app.tend.premium.monthly"

    var products: [String: Product] = [:]
    var purchasing = false
    var restoring = false
    var lastError: String?

    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored weak var model: AppModel?

    init() {}

    func start(model: AppModel) {
        self.model = model
        updates?.cancel()
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        guard let list = try? await Product.products(for: [Self.lifetimeID, Self.monthlyID]) else { return }
        products = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    func price(_ plan: PremiumPlan) -> String {
        switch plan {
        case .lifetime: products[Self.lifetimeID]?.displayPrice ?? "$59.99"
        case .monthly: products[Self.monthlyID]?.displayPrice ?? "$4.99"
        }
    }

    /// Returns true when the purchase went through.
    func purchase(_ plan: PremiumPlan) async -> Bool {
        let id = plan == .lifetime ? Self.lifetimeID : Self.monthlyID
        guard let product = products[id] else {
            #if DEBUG
            // No products (e.g. no StoreKit configuration selected): simulate in debug builds.
            try? await Task.sleep(for: .milliseconds(1300))
            model?.premium = plan
            return true
            #else
            lastError = "The App Store isn't available right now."
            return false
            #endif
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    await refreshEntitlements()
                    return true
                }
                return false
            default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Returns true when an earlier purchase was found.
    func restore() async -> Bool {
        try? await AppStore.sync()
        return await refreshEntitlements()
    }

    @discardableResult
    func refreshEntitlements() async -> Bool {
        var found: PremiumPlan?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result, t.revocationDate == nil else { continue }
            if t.productID == Self.lifetimeID { found = .lifetime }
            else if t.productID == Self.monthlyID, found == nil { found = .monthly }
        }
        if let found { model?.premium = found }
        return found != nil
    }
}
