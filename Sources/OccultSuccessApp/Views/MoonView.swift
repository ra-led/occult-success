import SwiftUI

struct MoonView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @State private var schedulingError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Лунный календарь",
                        title: "Сегодня",
                        subtitle: "Состояние ночного ритма, фаза и окно действия."
                    )

                    if let moon = appState.moonDay {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(moon.phaseName)
                                            .font(.callout.weight(.medium))
                                            .foregroundStyle(MysticTheme.muted)
                                        Text("\(moon.number)")
                                            .font(.system(size: 92, weight: .light, design: .serif))
                                            .foregroundStyle(MysticTheme.text)
                                            .lineLimit(1)
                                        Text("лунный день")
                                            .font(.title3.weight(.medium))
                                            .foregroundStyle(MysticTheme.gold)
                                    }
                                    Spacer()
                                    MoonOrb(illumination: moon.illumination)
                                        .frame(width: 96, height: 96)
                                }

                                MysticDivider()

                                HStack(alignment: .lastTextBaseline) {
                                    Text("\(Int(moon.illumination * 100))%")
                                        .font(.system(size: 44, weight: .light, design: .rounded))
                                    Text("освещённость")
                                        .font(.callout)
                                        .foregroundStyle(MysticTheme.muted)
                                }

                                Text(moon.advice)
                                    .font(.body)
                                    .foregroundStyle(MysticTheme.text.opacity(0.9))
                            }
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Час успеха", systemImage: "bell.badge")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(MysticTheme.gold)
                            Text("Пуш приходит в лучший момент дня, когда пора действовать: сделать звонок, отправить заявку или начать то, что откладывали.")
                                .foregroundStyle(MysticTheme.muted)
                            if subscriptionStore.isTrialActive {
                                Label("Бесплатный период: ещё \(subscriptionStore.trialDaysRemaining) дн.", systemImage: "gift")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(MysticTheme.emerald)
                            }

                            if subscriptionStore.isSuccessHourUnlocked {
                                MysticButton(title: "Запланировать окно", systemImage: "wand.and.stars") {
                                    Task {
                                        do {
                                            try await appState.scheduleSuccessHour()
                                            schedulingError = nil
                                        } catch {
                                            schedulingError = error.localizedDescription
                                        }
                                    }
                                }

                                if let hour = appState.lastSuccessHour {
                                    Text("Следующее окно: \(DateFormatter.shortMystic.string(from: hour.startsAt))")
                                        .font(.footnote)
                                        .foregroundStyle(MysticTheme.emerald)
                                }
                            } else {
                                MysticButton(title: "Открыть по подписке", systemImage: "lock.open") {
                                    Task { await subscriptionStore.buySuccessHour() }
                                }
                            }

                            if let schedulingError {
                                Text(schedulingError)
                                    .font(.footnote)
                                    .foregroundStyle(MysticTheme.danger)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 110)
            }
            .mysticScreen()
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }
}

private struct MoonOrb: View {
    let illumination: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .overlay {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.95), .blue.opacity(0.4), .clear],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 82
                            )
                        )
                        .opacity(max(0.18, illumination))
                }
                .overlay(Circle().stroke(MysticTheme.gold.opacity(0.45), lineWidth: 1))
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 12)
                .blur(radius: 7)
        }
    }
}
