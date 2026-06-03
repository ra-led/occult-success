import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Параметры",
                        title: "Настройки",
                        subtitle: "Ключи, модель сонника и локальный доступ к часу успеха."
                    )

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("OpenRouter")
                                .font(.title3.weight(.semibold))
                                .fontDesign(.serif)
                                .foregroundStyle(MysticTheme.gold)
                            MysticField(title: "API key", text: $appState.openRouterAPIKey, isSecure: true)
                            MysticField(title: "Base URL", text: $appState.openRouterBaseURL)
                            MysticField(title: "Модель сонника", text: $appState.openRouterModel)
                            Text("Сонник использует модель из этого поля. Натальная расшифровка всегда идет через openai/gpt-5.4.")
                                .font(.footnote)
                                .foregroundStyle(MysticTheme.muted)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Подписка")
                                .font(.title3.weight(.semibold))
                                .fontDesign(.serif)
                                .foregroundStyle(MysticTheme.gold)

                            if subscriptionStore.isTrialActive {
                                SettingRow(title: "Бесплатный период", value: "\(subscriptionStore.trialDaysRemaining) дн.")
                                SettingRow(title: "Доступен до", value: DateFormatter.shortMystic.string(from: subscriptionStore.trialEndsAt))
                            } else {
                                Text("Бесплатный период 3 недели завершён.")
                                    .foregroundStyle(MysticTheme.muted)
                            }

                            Toggle("Dev-доступ к часу успеха", isOn: Binding(
                                get: { subscriptionStore.devUnlocked },
                                set: { subscriptionStore.devUnlocked = $0 }
                            ))
                            .tint(MysticTheme.bone)

                            MysticButton(title: "Обновить StoreKit", systemImage: "arrow.clockwise") {
                                Task { await subscriptionStore.refresh() }
                            }

                            if let product = subscriptionStore.products.first {
                                SettingRow(title: "Продукт", value: "\(product.displayName), \(product.displayPrice)")
                            } else {
                                SettingRow(title: "Product id", value: "occultsuccess.success_hour.monthly")
                            }

                            if let error = subscriptionStore.errorMessage {
                                Text(error)
                                    .foregroundStyle(MysticTheme.danger)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 110)
            }
            .mysticScreen()
            .navigationTitle("")
        }
    }
}

private struct SettingRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(MysticTheme.muted)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(MysticTheme.text)
                .fontWeight(.medium)
        }
        .font(.callout)
        .fontDesign(.serif)
    }
}
