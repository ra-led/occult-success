import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .moon

    var body: some View {
        TabView(selection: $selectedTab) {
            MoonView()
                .tabItem { Label("Луна", systemImage: "moon.stars") }
                .tag(AppTab.moon)

            NatalChartView()
                .tabItem { Label("Карта", systemImage: "sparkles") }
                .tag(AppTab.natal)

            DreamBookView()
                .tabItem { Label("Сонник", systemImage: "cloud.moon") }
                .tag(AppTab.dream)

            SuccessHourView(selectedTab: $selectedTab)
                .tabItem { Label("Час", systemImage: "bell.badge") }
                .tag(AppTab.successHour)

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(MysticTheme.gold)
        #if os(iOS)
        .toolbarBackground(.black.opacity(0.82), for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        #endif
    }
}

enum AppTab: Hashable {
    case moon
    case natal
    case dream
    case successHour
    case settings
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionStore())
}
