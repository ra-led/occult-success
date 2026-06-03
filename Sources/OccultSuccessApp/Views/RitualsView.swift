import SwiftUI

struct SuccessHourView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @Binding var selectedTab: AppTab
    @State private var schedulingError: String?
    @State private var locationQuery = ""
    @State private var locationSuggestions: [BirthLocation] = []
    @State private var isSearchingLocation = false
    @State private var locationError: String?
    @State private var selectedLocationTitle: String?

    private let locationSearch = BirthLocationSearchService()

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
                        ActionLocationPanel(
                            query: $locationQuery,
                            selectedLocation: appState.successLocation,
                            suggestions: locationSuggestions,
                            isSearching: isSearchingLocation,
                            errorMessage: locationError,
                            selectLocation: selectLocation,
                            resetLocation: resetLocation
                        )
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
                            Text("Расчёт берёт вашу натальную карту как личную базу, а координаты и часовой пояс — из выбранного места действия. Если место не выбрано, используется город рождения из карты. При тех же данных окно будет тем же самым.")
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
            .onChange(of: locationQuery) { _, _ in
                guard locationQuery != selectedLocationTitle else { return }
                selectedLocationTitle = nil
                Task { await updateLocationSuggestions() }
            }
            .onAppear {
                if let location = appState.successLocation {
                    locationQuery = location.title
                    selectedLocationTitle = location.title
                }
            }
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

    private func updateLocationSuggestions() async {
        let query = locationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            locationSuggestions = []
            locationError = nil
            return
        }

        isSearchingLocation = true
        defer { isSearchingLocation = false }

        do {
            try await Task.sleep(nanoseconds: 350_000_000)
            guard query == locationQuery.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            locationSuggestions = try await locationSearch.searchCities(query)
            locationError = nil
        } catch is CancellationError {
        } catch {
            locationSuggestions = []
            locationError = error.localizedDescription
        }
    }

    private func selectLocation(_ location: BirthLocation) {
        selectedLocationTitle = location.title
        locationQuery = location.title
        locationSuggestions = []
        locationError = nil
        appState.setSuccessLocation(location)
    }

    private func resetLocation() {
        selectedLocationTitle = nil
        locationQuery = ""
        locationSuggestions = []
        locationError = nil
        appState.setSuccessLocation(nil)
    }
}

private struct ActionLocationPanel: View {
    @Binding var query: String
    let selectedLocation: BirthLocation?
    let suggestions: [BirthLocation]
    let isSearching: Bool
    let errorMessage: String?
    let selectLocation: (BirthLocation) -> Void
    let resetLocation: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label("Место действия", systemImage: "location")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(MysticTheme.gold)

                Text("Выберите город, где хотите использовать окно. Время пересчитается под это место.")
                    .font(.callout)
                    .foregroundStyle(MysticTheme.muted)

                MysticField(title: "Город для расчёта", text: $query)

                if isSearching {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(MysticTheme.bone)
                        Text("Ищу город")
                            .font(.caption)
                            .foregroundStyle(MysticTheme.muted)
                    }
                }

                if !suggestions.isEmpty {
                    SuccessLocationSuggestionsView(suggestions: suggestions, onSelect: selectLocation)
                }

                if let selectedLocation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLocation.title)
                            .font(.system(.callout, design: .serif).weight(.semibold))
                            .foregroundStyle(MysticTheme.bone)
                        if !selectedLocation.subtitle.isEmpty {
                            Text(selectedLocation.subtitle)
                                .font(.caption)
                                .foregroundStyle(MysticTheme.muted)
                        }
                        Text(selectedLocation.coordinateSummary)
                            .font(.caption)
                            .foregroundStyle(MysticTheme.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Button("Считать по месту рождения") {
                        resetLocation()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MysticTheme.muted)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(MysticTheme.danger)
                }
            }
        }
    }
}

private struct SuccessLocationSuggestionsView: View {
    let suggestions: [BirthLocation]
    let onSelect: (BirthLocation) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions) { location in
                Button {
                    onSelect(location)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.title)
                            .font(.system(.callout, design: .serif).weight(.semibold))
                            .foregroundStyle(MysticTheme.text)
                        if !location.subtitle.isEmpty {
                            Text(location.subtitle)
                                .font(.caption)
                                .foregroundStyle(MysticTheme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)

                if location.id != suggestions.last?.id {
                    MysticDivider()
                }
            }
        }
        .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
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
