import SwiftUI

struct SuccessHourView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @Binding var selectedTab: AppTab
    @State private var schedulingError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Персональное окно",
                        title: "Час успеха",
                        subtitle: "Лучшее время дня по месту и данным натальной карты."
                    )

                    if appState.natalChart == nil {
                        MissingNatalChartPanel(selectedTab: $selectedTab)
                    } else if let hour = appState.lastSuccessHour {
                        SuccessWindowPanel(hour: hour)
                        AccessPanel(
                            hour: hour,
                            schedulingError: schedulingError,
                            schedule: scheduleSuccessHour,
                            buy: { Task { await subscriptionStore.buySuccessHour() } }
                        )
                        .environmentObject(subscriptionStore)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Как считается", systemImage: "orbit")
                                .font(.title3.weight(.semibold))
                                .fontDesign(.serif)
                                .foregroundStyle(MysticTheme.gold)
                            Text("Расчёт берёт часовой пояс и координаты места рождения, положение Солнца, Луны и ASC в натальной карте, а затем накладывает текущий лунный день. Получается детерминированное окно: при тех же данных оно будет тем же самым.")
                                .font(.callout)
                                .foregroundStyle(MysticTheme.text.opacity(0.9))
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

    private func scheduleSuccessHour() {
        Task {
            do {
                try await appState.scheduleSuccessHour()
                schedulingError = nil
            } catch {
                schedulingError = error.localizedDescription
            }
        }
    }
}

private struct MissingNatalChartPanel: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("Нужна натальная карта", systemImage: "sparkles")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(MysticTheme.gold)
                Text("Чтобы посчитать личное окно успеха, нужны дата, время и город рождения. После расчёта карты этот экран сам покажет ближайший час.")
                    .foregroundStyle(MysticTheme.muted)
                MysticButton(title: "Рассчитать карту", systemImage: "arrow.right.circle") {
                    selectedTab = .natal
                }
            }
        }
    }
}

private struct SuccessWindowPanel: View {
    let hour: SuccessHour

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ближайшее окно")
                            .font(.system(.callout, design: .serif).weight(.medium))
                            .foregroundStyle(MysticTheme.muted)
                        Text(timeRange)
                            .font(.system(size: 38, weight: .light, design: .serif))
                            .foregroundStyle(MysticTheme.text)
                            .minimumScaleFactor(0.72)
                            .lineLimit(1)
                        Text(hour.locationName)
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundStyle(MysticTheme.gold)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(MysticTheme.gold.opacity(0.25), lineWidth: 1)
                        Circle()
                            .trim(from: 0, to: CGFloat(hour.score) / 100)
                            .stroke(MysticTheme.bone, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(hour.score)")
                            .font(.system(.title2, design: .serif).weight(.semibold))
                            .foregroundStyle(MysticTheme.text)
                    }
                    .frame(width: 74, height: 74)
                }

                MysticDivider()

                Text(hour.reason)
                    .font(.callout)
                    .foregroundStyle(MysticTheme.text.opacity(0.9))
            }
        }
    }

    private var timeRange: String {
        "\(DateFormatter.hourMinute(in: hour.timeZoneIdentifier).string(from: hour.startsAt))-\(DateFormatter.hourMinute(in: hour.timeZoneIdentifier).string(from: hour.endsAt))"
    }
}

private struct AccessPanel: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    let hour: SuccessHour
    let schedulingError: String?
    let schedule: () -> Void
    let buy: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label("Уведомление", systemImage: "bell.badge")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(MysticTheme.gold)

                if subscriptionStore.isTrialActive {
                    Label("Бесплатный период: ещё \(subscriptionStore.trialDaysRemaining) дн.", systemImage: "gift")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MysticTheme.bone)
                }

                Text("Пуш придёт в рассчитанный лучший момент, чтобы вы успели сделать действие внутри окна.")
                    .foregroundStyle(MysticTheme.muted)

                if subscriptionStore.isSuccessHourUnlocked {
                    MysticButton(title: "Запланировать на \(DateFormatter.hourMinute(in: hour.timeZoneIdentifier).string(from: hour.startsAt))", systemImage: "wand.and.stars") {
                        schedule()
                    }
                } else {
                    MysticButton(title: "Открыть по подписке", systemImage: "lock.open") {
                        buy()
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
}

private extension DateFormatter {
    static func hourMinute(in timeZoneIdentifier: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier)
        return formatter
    }
}
