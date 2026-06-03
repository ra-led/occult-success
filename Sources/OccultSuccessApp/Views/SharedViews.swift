import SwiftUI

struct MysticBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MysticTheme.void,
                    MysticTheme.ink,
                    Color(red: 0.012, green: 0.012, blue: 0.012)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            StarField()
                .opacity(0.82)

            OrbitalMap()
                .opacity(0.42)

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
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

                ForEach(0..<22, id: \.self) { index in
                    Circle()
                        .fill(.white.opacity(index.isMultiple(of: 3) ? 0.62 : 0.28))
                        .frame(width: index.isMultiple(of: 4) ? 1.8 : 0.9, height: index.isMultiple(of: 4) ? 1.8 : 0.9)
                        .position(
                            x: proxy.size.width * CGFloat((index * 37 % 100)) / 100,
                            y: proxy.size.height * CGFloat((index * 61 % 100)) / 100
                        )
                }
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
                        colors: [.clear, .white.opacity(0.07), .white.opacity(0.22)],
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
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MysticTheme.panel.opacity(0.88), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(.ultraThinMaterial.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [MysticTheme.gold.opacity(0.58), .white.opacity(0.12), MysticTheme.bone.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.42), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func mysticScreen() -> some View {
        self
            .foregroundStyle(MysticTheme.text)
            .scrollContentBackground(.hidden)
            .background(MysticBackground())
    }
}

enum MysticTheme {
    static let void = Color(red: 0.006, green: 0.008, blue: 0.012)
    static let ink = Color(red: 0.024, green: 0.024, blue: 0.026)
    static let panel = Color(red: 0.036, green: 0.035, blue: 0.034)
    static let field = Color(red: 0.014, green: 0.014, blue: 0.014)
    static let gold = Color(red: 0.82, green: 0.70, blue: 0.52)
    static let bone = Color(red: 0.78, green: 0.76, blue: 0.70)
    static let text = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let muted = Color(red: 0.66, green: 0.65, blue: 0.62)
    static let danger = Color(red: 0.86, green: 0.78, blue: 0.68)
    static let graphite = Color(red: 0.24, green: 0.235, blue: 0.225)
}

struct MysticPageTitle: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(MysticTheme.gold)
            Text(title)
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(MysticTheme.text)
            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(MysticTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MysticField: View {
    let title: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(.caption, design: .serif).weight(.semibold))
                .foregroundStyle(MysticTheme.gold.opacity(0.9))
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                }
            }
            .foregroundStyle(MysticTheme.text)
            .font(.body)
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(.white.opacity(0.13), lineWidth: 1)
            }
        }
    }
}

struct MysticTextBox: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(.caption, design: .serif).weight(.semibold))
                .foregroundStyle(MysticTheme.gold.opacity(0.9))
            TextEditor(text: $text)
                .foregroundStyle(MysticTheme.text)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: minHeight)
                .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.white.opacity(0.13), lineWidth: 1)
                }
        }
    }
}

struct MysticButton: View {
    let title: String
    let systemImage: String
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(.callout, design: .serif).weight(.semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [MysticTheme.gold, Color(red: 0.98, green: 0.84, blue: 0.52)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MysticDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, MysticTheme.gold.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
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
