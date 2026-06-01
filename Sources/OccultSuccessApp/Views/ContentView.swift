import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MoonView()
                .tabItem { Label("Луна", systemImage: "moon.stars") }

            NatalChartView()
                .tabItem { Label("Карта", systemImage: "sparkles") }

            DreamBookView()
                .tabItem { Label("Сонник", systemImage: "cloud.moon") }

            RitualsView()
                .tabItem { Label("Ритуалы", systemImage: "flame") }

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .tint(.purple)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionStore())
}
