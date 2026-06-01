import SwiftUI

struct MysticBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.06, blue: 0.12),
                Color(red: 0.12, green: 0.09, blue: 0.18),
                Color(red: 0.05, green: 0.08, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GlassPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12))
            }
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
