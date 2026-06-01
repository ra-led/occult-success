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
    @Published var rituals: [Ritual] = Ritual.seed
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
    }

    func calculateNatalChart(input: NatalChartInput) {
        natalChart = natalCalculator.calculate(input: input)
    }

    func toggleRitualStep(_ stepID: RitualStep.ID, in ritualID: Ritual.ID) {
        guard let ritualIndex = rituals.firstIndex(where: { $0.id == ritualID }),
              let stepIndex = rituals[ritualIndex].steps.firstIndex(where: { $0.id == stepID }) else { return }
        rituals[ritualIndex].steps[stepIndex].isDone.toggle()
    }

    func scheduleSuccessHour() async throws {
        lastSuccessHour = try await successScheduler.scheduleRandomWindow()
    }
}
