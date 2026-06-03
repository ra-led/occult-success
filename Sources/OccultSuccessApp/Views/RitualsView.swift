import SwiftUI

struct RitualsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Практики",
                        title: "Ритуалы",
                        subtitle: "Короткие последовательности действий: намерение, фокус, контроль."
                    )

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Снятие порчи", systemImage: "shield.lefthalf.filled")
                                .font(.title3.weight(.semibold))
                                .fontDesign(.serif)
                                .foregroundStyle(MysticTheme.gold)
                            Text("Мягкий бытовой сценарий: вода, порядок, границы и фиксация намерения. Без запугивания и вредных действий.")
                                .foregroundStyle(MysticTheme.muted)
                            MysticDivider()
                            Text("1. Умойтесь прохладной водой. 2. Выбросьте один ненужный предмет. 3. Запишите, что возвращаете себе контроль. 4. Сделайте практическое действие для безопасности и спокойствия.")
                                .font(.callout)
                                .foregroundStyle(MysticTheme.text.opacity(0.9))
                        }
                    }

                    ForEach($appState.rituals) { $ritual in
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(ritual.title, systemImage: ritual.accent)
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                Text(ritual.subtitle)
                                    .foregroundStyle(MysticTheme.muted)

                                RitualProgress(value: ritual.progress)

                                ForEach($ritual.steps) { $step in
                                    Button {
                                        appState.toggleRitualStep(step.id, in: ritual.id)
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .stroke(step.isDone ? MysticTheme.bone : MysticTheme.muted.opacity(0.45), lineWidth: 1)
                                                    .frame(width: 24, height: 24)
                                                if step.isDone {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundStyle(MysticTheme.bone)
                                                }
                                            }
                                            Text(step.title)
                                                .foregroundStyle(step.isDone ? MysticTheme.muted : MysticTheme.text)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
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
}

private struct RitualProgress: View {
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.08))
                    Capsule()
                        .fill(MysticTheme.bone)
                        .frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 5)

            Text("\(Int(value * 100))% завершено")
                .font(.caption)
                .fontDesign(.serif)
                .foregroundStyle(MysticTheme.muted)
        }
    }
}
