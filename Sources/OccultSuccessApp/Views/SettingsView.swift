import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenRouter") {
                    SecureField("API key", text: $appState.openRouterAPIKey)
                    plainTextField("Base URL", text: $appState.openRouterBaseURL)
                    plainTextField("Model", text: $appState.openRouterModel)
                    Text("Ключ используется только для сонника. Для продакшена его лучше хранить за backend-proxy, а не в iOS-клиенте.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Подписка") {
                    if subscriptionStore.isTrialActive {
                        LabeledContent("Бесплатный период", value: "\(subscriptionStore.trialDaysRemaining) дн.")
                        LabeledContent("Доступен до", value: DateFormatter.shortMystic.string(from: subscriptionStore.trialEndsAt))
                    } else {
                        Text("Бесплатный период 3 недели завершён.")
                    }

                    Toggle("Dev-доступ к часу успеха", isOn: Binding(
                        get: { subscriptionStore.devUnlocked },
                        set: { subscriptionStore.devUnlocked = $0 }
                    ))

                    Button("Обновить StoreKit") {
                        Task { await subscriptionStore.refresh() }
                    }

                    if let product = subscriptionStore.products.first {
                        Text("Продукт: \(product.displayName), \(product.displayPrice)")
                    } else {
                        Text("Product id: occultsuccess.success_hour.monthly")
                    }

                    if let error = subscriptionStore.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MysticBackground())
            .navigationTitle("Настройки")
        }
    }

    private func plainTextField(_ title: String, text: Binding<String>) -> some View {
        #if os(iOS)
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        TextField(title, text: text)
        #endif
    }
}
