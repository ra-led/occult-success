import SwiftUI

struct MoonView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @State private var schedulingError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Сегодня")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)

                    if let moon = appState.moonDay {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("\(moon.number)-й лунный день")
                                    .font(.largeTitle.bold())
                                Text(moon.phaseName)
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.78))
                                ProgressView(value: moon.illumination)
                                    .tint(.yellow)
                                Text("Освещённость: \(Int(moon.illumination * 100))%")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(moon.advice)
                                    .font(.body)
                            }
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Час успеха", systemImage: "bell.badge")
                                .font(.title3.bold())
                            Text("Пуш приходит в случайный момент дня, когда лучше сделать действие, которое вы давно откладывали.")
                                .foregroundStyle(.white.opacity(0.76))
                            if subscriptionStore.isTrialActive {
                                Label("Бесплатный период: ещё \(subscriptionStore.trialDaysRemaining) дн.", systemImage: "gift")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.green)
                            }

                            if subscriptionStore.isSuccessHourUnlocked {
                                Button {
                                    Task {
                                        do {
                                            try await appState.scheduleSuccessHour()
                                            schedulingError = nil
                                        } catch {
                                            schedulingError = error.localizedDescription
                                        }
                                    }
                                } label: {
                                    Label("Запланировать окно", systemImage: "wand.and.stars")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)

                                if let hour = appState.lastSuccessHour {
                                    Text("Следующее окно: \(DateFormatter.shortMystic.string(from: hour.startsAt))")
                                        .font(.footnote)
                                        .foregroundStyle(.green)
                                }
                            } else {
                                Button {
                                    Task { await subscriptionStore.buySuccessHour() }
                                } label: {
                                    Label("Открыть по подписке", systemImage: "lock.open")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            if let schedulingError {
                                Text(schedulingError)
                                    .font(.footnote)
                                    .foregroundStyle(.red.opacity(0.9))
                            }
                        }
                    }
                }
                .padding()
            }
            .mysticScreen()
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }
}
