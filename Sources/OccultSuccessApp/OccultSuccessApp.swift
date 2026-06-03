import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct OccultSuccessApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionStore = SubscriptionStore()

    init() {
        #if os(iOS)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(subscriptionStore)
                .task {
                    await subscriptionStore.refresh()
                    await appState.refreshToday()
                }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var moonDay: MoonDay?
    @Published var dreamInterpretations: [DreamInterpretation] = []
    @Published var natalChart: NatalChart?
    @Published var lastSuccessHour: SuccessHour?
    @Published var openRouterAPIKey: String = UserDefaults.standard.string(forKey: "openRouterAPIKey") ?? "" {
        didSet { UserDefaults.standard.set(openRouterAPIKey, forKey: "openRouterAPIKey") }
    }
    @Published var openRouterBaseURL: String = UserDefaults.standard.string(forKey: "openRouterBaseURL") ?? "https://openrouter.ai/api/v1" {
        didSet { UserDefaults.standard.set(openRouterBaseURL, forKey: "openRouterBaseURL") }
    }
    @Published var openRouterModel: String = UserDefaults.standard.string(forKey: "openRouterModel") ?? "openai/gpt-5.4-mini" {
        didSet { UserDefaults.standard.set(openRouterModel, forKey: "openRouterModel") }
    }

    private let moonService = MoonCalendarService()
    private let natalCalculator = NatalChartCalculator()
    private let successScheduler = SuccessHourScheduler()

    func refreshToday(now: Date = .now) async {
        moonDay = moonService.moonDay(for: now)
        refreshSuccessHour(now: now)
    }

    func calculateNatalChart(input: NatalChartInput) {
        natalChart = natalCalculator.calculate(input: input)
        refreshSuccessHour()
    }

    func refreshSuccessHour(now: Date = .now) {
        guard let natalChart, let moonDay else {
            lastSuccessHour = nil
            return
        }
        lastSuccessHour = successScheduler.calculateWindow(natalChart: natalChart, moonDay: moonDay, now: now)
    }

    func scheduleSuccessHour() async throws {
        refreshSuccessHour()
        guard let lastSuccessHour else {
            throw NSError(domain: "SuccessHour", code: 2, userInfo: [NSLocalizedDescriptionKey: "Сначала рассчитайте натальную карту."])
        }
        try await successScheduler.scheduleWindow(lastSuccessHour)
    }
}
