import SwiftUI

struct RitualsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Снятие порчи", systemImage: "shield.lefthalf.filled")
                                .font(.title3.bold())
                            Text("Мягкий бытовой сценарий: вода, порядок, границы и фиксация намерения. Без запугивания и вредных действий.")
                                .foregroundStyle(.white.opacity(0.78))
                            Text("1. Умойтесь прохладной водой. 2. Выбросьте один ненужный предмет. 3. Запишите, что возвращаете себе контроль. 4. Сделайте практическое действие для безопасности и спокойствия.")
                                .font(.callout)
                        }
                    }

                    ForEach($appState.rituals) { $ritual in
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(ritual.title, systemImage: ritual.accent)
                                    .font(.title3.bold())
                                Text(ritual.subtitle)
                                    .foregroundStyle(.white.opacity(0.72))
                                ProgressView(value: ritual.progress)
                                    .tint(.green)
                                Text("\(Int(ritual.progress * 100))% завершено")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.62))

                                ForEach($ritual.steps) { $step in
                                    Button {
                                        appState.toggleRitualStep(step.id, in: ritual.id)
                                    } label: {
                                        HStack {
                                            Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(step.isDone ? .green : .white.opacity(0.5))
                                            Text(step.title)
                                                .foregroundStyle(.white)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .mysticScreen()
            .navigationTitle("Ритуалы")
        }
    }
}
