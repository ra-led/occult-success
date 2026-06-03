import SwiftUI

struct MoonView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Лунный календарь",
                        title: "Сегодня",
                        subtitle: "Состояние ночного ритма, фаза и практический смысл дня."
                    )

                    if let moon = appState.moonDay {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(moon.phaseName)
                                            .font(.system(.callout, design: .serif).weight(.medium))
                                            .foregroundStyle(MysticTheme.muted)
                                        Text("\(moon.number)")
                                            .font(.system(size: 92, weight: .light, design: .serif))
                                            .foregroundStyle(MysticTheme.text)
                                            .lineLimit(1)
                                        Text("лунный день")
                                            .font(.system(.title3, design: .serif).weight(.medium))
                                            .foregroundStyle(MysticTheme.gold)
                                    }
                                    Spacer()
                                    MoonOrb(illumination: moon.illumination, cycleFraction: moon.cycleFraction)
                                        .frame(width: 96, height: 96)
                                }

                                MysticDivider()

                                HStack(alignment: .lastTextBaseline) {
                                    Text("\(Int(moon.illumination * 100))%")
                                        .font(.system(size: 44, weight: .light, design: .rounded))
                                    Text("освещённость")
                                        .font(.system(.callout, design: .serif))
                                        .foregroundStyle(MysticTheme.muted)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(moon.guidance.title)
                                        .font(.system(.title3, design: .serif).weight(.semibold))
                                        .foregroundStyle(MysticTheme.bone)
                                    Text(moon.guidance.description)
                                        .font(.body)
                                        .foregroundStyle(MysticTheme.text.opacity(0.9))
                                }
                            }
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Фокус дня: \(moon.guidance.focus)", systemImage: "scope")
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)

                                ForEach(moon.guidance.actions, id: \.self) { action in
                                    HStack(alignment: .top, spacing: 9) {
                                        Text("•")
                                            .foregroundStyle(MysticTheme.gold)
                                        Text(action)
                                            .font(.callout)
                                            .foregroundStyle(MysticTheme.text.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 110)
            }
            .mysticScreen()
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }
}

private struct MoonOrb: View {
    let illumination: Double
    let cycleFraction: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            MysticTheme.bone,
                            MysticTheme.gold.opacity(0.42)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 92
                    )
                )
                .overlay {
                    MoonPhaseShadow(cycleFraction: cycleFraction, illumination: illumination)
                        .fill(.black.opacity(0.82))
                        .blur(radius: 0.5)
                        .clipShape(Circle())
                }
                .overlay {
                    Circle()
                        .stroke(MysticTheme.gold.opacity(0.5), lineWidth: 1)
                }
                .shadow(color: MysticTheme.bone.opacity(0.28), radius: 18)
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 12)
                .blur(radius: 7)
        }
    }
}

private struct MoonPhaseShadow: Shape {
    let cycleFraction: Double
    let illumination: Double

    func path(in rect: CGRect) -> Path {
        let safeIllumination = min(1, max(0, illumination))
        guard safeIllumination < 0.985 else { return Path() }
        guard safeIllumination > 0.02 else {
            var path = Path()
            path.addEllipse(in: rect)
            return path
        }

        let diameter = min(rect.width, rect.height)
        let shadowWidth = max(diameter * (1 - safeIllumination), diameter * 0.055)
        let cycle = min(1, max(0, cycleFraction))
        let isWaxing = cycle < 0.5
        let shadowRect: CGRect

        if isWaxing {
            shadowRect = CGRect(
                x: rect.minX - shadowWidth,
                y: rect.minY - diameter * 0.08,
                width: shadowWidth * 2,
                height: rect.height + diameter * 0.16
            )
        } else {
            shadowRect = CGRect(
                x: rect.maxX - shadowWidth,
                y: rect.minY - diameter * 0.08,
                width: shadowWidth * 2,
                height: rect.height + diameter * 0.16
            )
        }

        var path = Path()
        path.addEllipse(in: shadowRect)
        return path
    }
}
