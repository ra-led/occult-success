import SwiftUI

struct DreamBookView: View {
    @EnvironmentObject private var appState: AppState
    @State private var dream = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let service = OpenRouterDreamService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Сонник",
                        title: "Запись сна",
                        subtitle: "Опишите образ, место и чувство. Толкование соберет символы в цельную историю."
                    )

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            MysticTextBox(title: "Сон", text: $dream, minHeight: 160)

                            MysticButton(title: "Истолковать через LLM", systemImage: "sparkle.magnifyingglass", isLoading: isLoading) {
                                Task { await interpret() }
                            }
                            .disabled(dream.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(MysticTheme.danger)
                            }
                        }
                    }

                    ForEach(appState.dreamInterpretations) { item in
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.dream)
                                    .font(.headline.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                    .lineLimit(2)
                                Text(item.text)
                                    .foregroundStyle(MysticTheme.text.opacity(0.86))
                                Text(DateFormatter.shortMystic.string(from: item.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(MysticTheme.muted)
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

    private func interpret() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let text = try await service.interpret(
                dream: dream,
                apiKey: appState.openRouterAPIKey,
                baseURL: appState.openRouterBaseURL,
                model: appState.openRouterModel
            )
            appState.dreamInterpretations.insert(DreamInterpretation(dream: dream, text: text, createdAt: .now), at: 0)
            dream = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
