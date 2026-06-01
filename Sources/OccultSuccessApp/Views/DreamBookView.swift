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
                VStack(spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Опишите сон")
                                .font(.title3.bold())
                            TextEditor(text: $dream)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))

                            Button {
                                Task { await interpret() }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Label("Истолковать через LLM", systemImage: "sparkle.magnifyingglass")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(dream.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red.opacity(0.9))
                            }
                        }
                    }

                    ForEach(appState.dreamInterpretations) { item in
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.dream)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(item.text)
                                    .foregroundStyle(.white.opacity(0.82))
                                Text(DateFormatter.shortMystic.string(from: item.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }
                }
                .padding()
            }
            .mysticScreen()
            .navigationTitle("Сонник")
        }
    }

    private func interpret() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let text = try await service.interpret(dream: dream, apiKey: appState.openRouterAPIKey)
            appState.dreamInterpretations.insert(DreamInterpretation(dream: dream, text: text, createdAt: .now), at: 0)
            dream = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
