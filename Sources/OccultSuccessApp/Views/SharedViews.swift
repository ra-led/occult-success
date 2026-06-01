import SwiftUI

struct MysticBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.09),
                    Color(red: 0.08, green: 0.05, blue: 0.18),
                    Color(red: 0.02, green: 0.09, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            StarField()
                .opacity(0.92)

            OrbitalMap()
                .opacity(0.7)
        }
        .ignoresSafeArea()
    }
}

private struct StarField: View {
    private let stars: [Star] = [
        Star(x: 0.08, y: 0.12, size: 1.2, opacity: 0.72),
        Star(x: 0.18, y: 0.32, size: 1.6, opacity: 0.58),
        Star(x: 0.26, y: 0.08, size: 1.1, opacity: 0.66),
        Star(x: 0.36, y: 0.22, size: 1.8, opacity: 0.82),
        Star(x: 0.47, y: 0.11, size: 1.2, opacity: 0.6),
        Star(x: 0.58, y: 0.36, size: 1.5, opacity: 0.72),
        Star(x: 0.69, y: 0.18, size: 1.1, opacity: 0.52),
        Star(x: 0.82, y: 0.29, size: 1.9, opacity: 0.82),
        Star(x: 0.92, y: 0.08, size: 1.3, opacity: 0.64),
        Star(x: 0.12, y: 0.57, size: 1.1, opacity: 0.5),
        Star(x: 0.31, y: 0.72, size: 1.4, opacity: 0.55),
        Star(x: 0.52, y: 0.63, size: 1.2, opacity: 0.5),
        Star(x: 0.76, y: 0.78, size: 1.5, opacity: 0.6),
        Star(x: 0.91, y: 0.61, size: 1.1, opacity: 0.48)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(x: proxy.size.width * star.x, y: proxy.size.height * star.y)
                }

                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.cyan.opacity(0.55))
                    .position(x: proxy.size.width * 0.86, y: proxy.size.height * 0.16)

                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(.purple.opacity(0.62))
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.68)
            }
        }
    }
}

private struct OrbitalMap: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    Ellipse()
                        .stroke(.white.opacity(0.06 + Double(index) * 0.018), lineWidth: 1)
                        .frame(
                            width: proxy.size.width * (0.72 + CGFloat(index) * 0.18),
                            height: proxy.size.height * (0.19 + CGFloat(index) * 0.055)
                        )
                        .rotationEffect(.degrees(-24 + Double(index) * 8))
                        .position(x: proxy.size.width * 0.68, y: proxy.size.height * 0.22)
                }

                Planet(color: .cyan, size: 56)
                    .position(x: proxy.size.width * 0.87, y: proxy.size.height * 0.2)

                Planet(color: .purple, size: 34)
                    .position(x: proxy.size.width * 0.14, y: proxy.size.height * 0.78)

                Comet()
                    .frame(width: 130, height: 42)
                    .rotationEffect(.degrees(-18))
                    .position(x: proxy.size.width * 0.74, y: proxy.size.height * 0.57)
            }
        }
    }
}

private struct Planet: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.74), color.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 2,
                    endRadius: size * 0.72
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                    .padding(size * 0.22)
            }
    }
}

private struct Comet: View {
    var body: some View {
        ZStack(alignment: .trailing) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.clear, .cyan.opacity(0.09), .white.opacity(0.24)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            Circle()
                .fill(.white.opacity(0.62))
                .frame(width: 5, height: 5)
        }
    }
}

private struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

struct GlassPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.105), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.16))
            }
            .shadow(color: .cyan.opacity(0.08), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func mysticScreen() -> some View {
        self
            .foregroundStyle(.white)
            .scrollContentBackground(.hidden)
            .background(MysticBackground())
    }
}

extension DateFormatter {
    static let shortMystic: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
