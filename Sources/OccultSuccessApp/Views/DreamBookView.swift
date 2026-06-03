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
                            VStack(alignment: .leading, spacing: 14) {
                                Text(item.dream)
                                    .font(.headline.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                    .lineLimit(2)
                                DreamInterpretationReportView(report: item.report)
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
            let report = try await service.interpret(
                dream: dream,
                apiKey: appState.openRouterAPIKey,
                baseURL: appState.openRouterBaseURL,
                model: appState.openRouterModel
            )
            appState.dreamInterpretations.insert(DreamInterpretation(dream: dream, report: report, createdAt: .now), at: 0)
            dream = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct DreamInterpretationReportView: View {
    let report: DreamInterpretationReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(report.sections) { section in
                VStack(alignment: .leading, spacing: 9) {
                    Text(section.title)
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(MysticTheme.bone)

                    ForEach(section.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.callout)
                            .foregroundStyle(MysticTheme.text.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !section.symbols.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(section.symbols) { symbol in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(symbol.name)
                                        .font(.system(.callout, design: .serif).weight(.semibold))
                                        .foregroundStyle(MysticTheme.gold)
                                    Text(symbol.meaning)
                                        .font(.callout)
                                        .foregroundStyle(MysticTheme.text.opacity(0.86))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }

                    if !section.bullets.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(section.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(MysticTheme.gold)
                                    Text(bullet)
                                        .foregroundStyle(MysticTheme.text.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .font(.callout)
                            }
                        }
                    }
                }
            }
        }
    }
}
