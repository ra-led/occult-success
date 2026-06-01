import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published var products: [Product] = []
    @Published var isSuccessHourUnlocked: Bool
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productIDs = ["occultsuccess.success_hour.monthly"]
    private static let trialStartKey = "successHourTrialStartedAt"
    private static let trialDuration: TimeInterval = 21 * 24 * 60 * 60

    init() {
        Self.ensureTrialStarted()
        isSuccessHourUnlocked = Self.isTrialActive || UserDefaults.standard.bool(forKey: "successHourDevUnlocked")
    }

    var isTrialActive: Bool {
        Self.isTrialActive
    }

    var trialEndsAt: Date {
        Self.trialStartedAt.addingTimeInterval(Self.trialDuration)
    }

    var trialDaysRemaining: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: trialEndsAt)
        return max(0, (components.day ?? 0) + 1)
    }

    var devUnlocked: Bool {
        get { UserDefaults.standard.bool(forKey: "successHourDevUnlocked") }
        set {
            UserDefaults.standard.set(newValue, forKey: "successHourDevUnlocked")
            isSuccessHourUnlocked = isTrialActive || newValue
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            var unlocked = isTrialActive || devUnlocked
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if productIDs.contains(transaction.productID) {
                    unlocked = true
                }
            }
            isSuccessHourUnlocked = unlocked
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func buySuccessHour() async {
        guard let product = products.first else {
            errorMessage = "Подписка ещё не загружена. Для локального теста включите dev-доступ."
            return
        }

        do {
            let result = try await product.purchase()
            if case .success(.verified(let transaction)) = result {
                await transaction.finish()
                isSuccessHourUnlocked = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static var trialStartedAt: Date {
        ensureTrialStarted()
        return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: trialStartKey))
    }

    private static var isTrialActive: Bool {
        Date() < trialStartedAt.addingTimeInterval(trialDuration)
    }

    private static func ensureTrialStarted() {
        guard UserDefaults.standard.double(forKey: trialStartKey) == 0 else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: trialStartKey)
    }
}
