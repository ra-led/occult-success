import SwiftUI

struct NatalChartView: View {
    @EnvironmentObject private var appState: AppState
    @State private var input = NatalChartInput()
    @State private var isSearching = false
    @State private var isInterpreting = false
    @State private var searchError: String?
    @State private var interpretationError: String?
    @State private var llmInterpretation: NatalInterpretationReport?
    @State private var locationSuggestions: [BirthLocation] = []
    @State private var selectedLocationTitle: String?

    private let locationSearch = BirthLocationSearchService()
    private let natalLLMService = OpenRouterNatalService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MysticPageTitle(
                        eyebrow: "Астрология",
                        title: "Натальная карта",
                        subtitle: "Точный расчет по месту, времени, Placidus-домам и аспектам."
                    )

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            MysticField(title: "Имя", text: $input.name)

                            VStack(alignment: .leading, spacing: 7) {
                                Text("Дата и время")
                                    .font(.system(.caption, design: .serif).weight(.semibold))
                                    .foregroundStyle(MysticTheme.gold.opacity(0.9))
                                DatePicker("", selection: $input.birthDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(MysticTheme.gold)
                                    .foregroundStyle(MysticTheme.text)
                                    .environment(\.colorScheme, .dark)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 46)
                                    .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(.white.opacity(0.13), lineWidth: 1)
                                    }
                            }

                            MysticField(title: "Город рождения", text: $input.birthPlace)
                            if isSearching {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(MysticTheme.bone)
                                    Text("Ищу город")
                                        .font(.caption)
                                        .foregroundStyle(MysticTheme.muted)
                                }
                            }
                            if !locationSuggestions.isEmpty {
                                LocationSuggestionsView(suggestions: locationSuggestions) { location in
                                    selectLocation(location)
                                }
                            }
                            HouseSystemSelector(selection: $input.houseSystem)

                            if let searchError {
                                Text(searchError)
                                    .font(.footnote)
                                    .foregroundStyle(MysticTheme.danger)
                            }

                            if let location = input.birthLocation {
                                LocationPreview(location: location)
                            }

                            MysticButton(title: "Рассчитать натальную карту", systemImage: "scope") {
                                Task { await calculateChart() }
                            }
                        }
                    }
                    .onChange(of: input.birthPlace) { _, _ in
                        guard input.birthPlace != selectedLocationTitle else { return }
                        input.birthLocation = nil
                        selectedLocationTitle = nil
                        Task { await updateLocationSuggestions() }
                    }

                    if let chart = appState.natalChart {
                        GlassPanel {
                            NatalChartWheelView(chart: chart)
                                .frame(height: 360)
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(chart.name)
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                if let location = chart.location {
                                    MysticInfoRow(title: "Место", value: location.title)
                                }
                                MysticInfoRow(title: "Дома", value: chart.houseSystem.rawValue)
                                MysticDivider()
                                ForEach(chart.placements) { placement in
                                    MysticInfoRow(title: placement.body.rawValue, value: placement.formattedPosition)
                                }
                                Text(chart.interpretation)
                                    .font(.callout)
                                    .foregroundStyle(MysticTheme.muted)
                                    .padding(.top, 4)
                            }
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("LLM-расшифровка")
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                MysticButton(title: "Расшифровать через GPT-5.4", systemImage: "sparkles", isLoading: isInterpreting) {
                                    Task { await interpretNatalChart(chart) }
                                }
                                .disabled(isInterpreting)

                                Text("Модель: \(OpenRouterNatalService.natalModel)")
                                    .font(.caption)
                                    .foregroundStyle(MysticTheme.muted)

                                if let interpretationError {
                                    Text(interpretationError)
                                        .font(.footnote)
                                        .foregroundStyle(MysticTheme.danger)
                                }

                                if let llmInterpretation {
                                    MysticDivider()
                                    NatalInterpretationReportView(report: llmInterpretation)
                                }
                            }
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Дома")
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                ForEach(chart.houses) { house in
                                    MysticInfoRow(title: "\(house.number)", value: house.formattedPosition)
                                }
                            }
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Аспекты")
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(MysticTheme.gold)
                                if chart.aspects.isEmpty {
                                    Text("Мажорных аспектов с орбом до 6° нет.")
                                        .foregroundStyle(MysticTheme.muted)
                                } else {
                                    ForEach(chart.aspects.prefix(12)) { aspect in
                                        Text(aspect.title)
                                            .font(.callout)
                                            .foregroundStyle(MysticTheme.text.opacity(0.9))
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
            .navigationTitle("")
        }
    }

    private func searchBirthPlace() async {
        isSearching = true
        defer { isSearching = false }

        do {
            let location = try await locationSearch.searchCity(input.birthPlace)
            selectLocation(location)
        } catch {
            searchError = error.localizedDescription
        }
    }

    private func updateLocationSuggestions() async {
        let query = input.birthPlace.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            locationSuggestions = []
            searchError = nil
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            try await Task.sleep(nanoseconds: 350_000_000)
            guard query == input.birthPlace.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            locationSuggestions = try await locationSearch.searchCities(query)
            searchError = nil
        } catch is CancellationError {
        } catch {
            locationSuggestions = []
            searchError = error.localizedDescription
        }
    }

    private func selectLocation(_ location: BirthLocation) {
        selectedLocationTitle = location.title
        input.birthPlace = location.title
        input.birthLocation = location
        locationSuggestions = []
        searchError = nil
    }

    private func calculateChart() async {
        if input.birthLocation == nil && !input.birthPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await searchBirthPlace()
        }

        appState.calculateNatalChart(input: input)
        llmInterpretation = nil
        interpretationError = nil
    }

    private func interpretNatalChart(_ chart: NatalChart) async {
        isInterpreting = true
        defer { isInterpreting = false }

        do {
            llmInterpretation = try await natalLLMService.interpret(
                chart: chart,
                apiKey: appState.openRouterAPIKey,
                baseURL: appState.openRouterBaseURL
            )
            interpretationError = nil
        } catch {
            interpretationError = error.localizedDescription
        }
    }
}

private struct HouseSystemSelector: View {
    @Binding var selection: HouseSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Система домов")
                .font(.caption.weight(.semibold))
                .fontDesign(.serif)
                .foregroundStyle(MysticTheme.gold.opacity(0.9))
            HStack(spacing: 8) {
                ForEach(HouseSystem.allCases) { system in
                    Button {
                        selection = system
                    } label: {
                        Text(system.rawValue)
                            .font(.caption.weight(.semibold))
                            .fontDesign(.serif)
                            .foregroundStyle(selection == system ? .black : MysticTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(selection == system ? MysticTheme.gold : MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(selection == system ? MysticTheme.gold : .white.opacity(0.14), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct LocationPreview: View {
    let location: BirthLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(location.title)
                .font(.headline)
                .foregroundStyle(MysticTheme.text)
            if !location.subtitle.isEmpty {
                Text(location.subtitle)
                    .font(.footnote)
                    .foregroundStyle(MysticTheme.muted)
            }
            Text(location.coordinateSummary)
                .font(.caption)
                .foregroundStyle(MysticTheme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(MysticTheme.gold.opacity(0.24), lineWidth: 1)
        }
        .padding(.top, 4)
    }
}

private struct LocationSuggestionsView: View {
    let suggestions: [BirthLocation]
    let onSelect: (BirthLocation) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions) { location in
                Button {
                    onSelect(location)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.title)
                            .font(.system(.callout, design: .serif).weight(.semibold))
                            .foregroundStyle(MysticTheme.text)
                        if !location.subtitle.isEmpty {
                            Text(location.subtitle)
                                .font(.caption)
                                .foregroundStyle(MysticTheme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)

                if location.id != suggestions.last?.id {
                    MysticDivider()
                }
            }
        }
        .background(MysticTheme.field, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct MysticInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.callout)
                .fontDesign(.serif)
                .foregroundStyle(MysticTheme.muted)
            Spacer(minLength: 8)
            Text(value)
                .font(.callout.weight(.medium))
                .fontDesign(.serif)
                .foregroundStyle(MysticTheme.text)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

private struct NatalInterpretationReportView: View {
    let report: NatalInterpretationReport

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(report.sections) { section in
                VStack(alignment: .leading, spacing: 9) {
                    Text(section.title)
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(MysticTheme.gold)
                    ForEach(section.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.callout)
                            .foregroundStyle(MysticTheme.text.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !section.bullets.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(section.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(MysticTheme.gold)
                                    Text(bullet)
                                        .foregroundStyle(MysticTheme.text.opacity(0.9))
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

private struct NatalChartWheelView: View {
    let chart: NatalChart

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let outerRadius = size * 0.46
            let zodiacRadius = size * 0.39
            let houseRadius = size * 0.31
            let planetRadius = size * 0.24

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.indigo.opacity(0.45),
                                Color.black.opacity(0.35),
                                MysticTheme.graphite.opacity(0.72)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: outerRadius
                        )
                    )
                    .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1.2))
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .position(center)

                ForEach(0..<12, id: \.self) { index in
                    let longitude = Double(index) * 30
                    ChartRadialLine(center: center, radius: outerRadius, longitude: longitude)
                        .stroke(.white.opacity(0.20), lineWidth: 1)
                    Text(zodiacGlyph(for: ZodiacSign.allCases[index]))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .position(point(center: center, radius: zodiacRadius, longitude: longitude + 15))
                }

                ForEach(chart.houses) { house in
                    ChartRadialLine(center: center, radius: outerRadius * 0.94, longitude: house.longitude)
                        .stroke(house.number == 1 || house.number == 10 ? MysticTheme.gold.opacity(0.78) : MysticTheme.muted.opacity(0.38), lineWidth: house.number == 1 || house.number == 10 ? 2.4 : 1.2)
                    Text("\(house.number)")
                        .font(.caption2.bold())
                        .foregroundStyle(MysticTheme.gold.opacity(0.9))
                        .position(point(center: center, radius: houseRadius, longitude: house.longitude + 4))
                }

                AspectLines(chart: chart, center: center, radius: planetRadius)

                ForEach(chart.placements) { placement in
                    let radius = placement.body == .ascendant || placement.body == .midheaven ? outerRadius * 0.70 : planetRadius
                    Text(placement.body.glyph)
                        .font(.system(size: placement.body == .ascendant || placement.body == .midheaven ? 16 : 22, weight: .bold))
                        .foregroundStyle(color(for: placement.body))
                        .shadow(color: .black.opacity(0.4), radius: 3)
                        .position(point(center: center, radius: radius, longitude: placement.longitude))
                }

                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
                    .frame(width: planetRadius * 2, height: planetRadius * 2)
                    .position(center)
                Circle()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
                    .frame(width: houseRadius * 2, height: houseRadius * 2)
                    .position(center)
            }
        }
        .accessibilityLabel("Круговая натальная карта")
    }

    private func point(center: CGPoint, radius: CGFloat, longitude: Double) -> CGPoint {
        let angle = CGFloat((longitude - 90) * .pi / 180)
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func zodiacGlyph(for sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "♈︎"
        case .taurus: return "♉︎"
        case .gemini: return "♊︎"
        case .cancer: return "♋︎"
        case .leo: return "♌︎"
        case .virgo: return "♍︎"
        case .libra: return "♎︎"
        case .scorpio: return "♏︎"
        case .sagittarius: return "♐︎"
        case .capricorn: return "♑︎"
        case .aquarius: return "♒︎"
        case .pisces: return "♓︎"
        }
    }

    private func color(for body: CelestialBody) -> Color {
        switch body {
        case .sun: return MysticTheme.gold
        case .moon: return MysticTheme.text
        case .mercury: return MysticTheme.muted
        case .venus: return Color(red: 0.84, green: 0.81, blue: 0.74)
        case .mars: return Color(red: 0.72, green: 0.69, blue: 0.63)
        case .jupiter: return Color(red: 0.88, green: 0.84, blue: 0.76)
        case .saturn: return Color(red: 0.58, green: 0.56, blue: 0.52)
        case .uranus: return Color(red: 0.76, green: 0.76, blue: 0.73)
        case .neptune: return Color(red: 0.68, green: 0.68, blue: 0.66)
        case .pluto: return Color(red: 0.62, green: 0.60, blue: 0.57)
        case .ascendant, .midheaven: return MysticTheme.gold.opacity(0.88)
        }
    }
}

private struct ChartRadialLine: Shape {
    let center: CGPoint
    let radius: CGFloat
    let longitude: Double

    func path(in rect: CGRect) -> Path {
        let angle = CGFloat((longitude - 90) * .pi / 180)
        let end = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        var path = Path()
        path.move(to: center)
        path.addLine(to: end)
        return path
    }
}

private struct AspectLines: View {
    let chart: NatalChart
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        ForEach(chart.aspects.prefix(18)) { aspect in
            if let first = chart.placements.first(where: { $0.body == aspect.first }),
               let second = chart.placements.first(where: { $0.body == aspect.second }) {
                Path { path in
                    path.move(to: point(longitude: first.longitude))
                    path.addLine(to: point(longitude: second.longitude))
                }
                .stroke(color(for: aspect.kind).opacity(0.38), lineWidth: 1)
            }
        }
    }

    private func point(longitude: Double) -> CGPoint {
        let angle = CGFloat((longitude - 90) * .pi / 180)
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func color(for kind: AspectKind) -> Color {
        switch kind {
        case .conjunction: return MysticTheme.text
        case .sextile: return MysticTheme.muted
        case .square: return MysticTheme.gold.opacity(0.75)
        case .trine: return Color(red: 0.74, green: 0.72, blue: 0.68)
        case .opposition: return Color(red: 0.58, green: 0.56, blue: 0.52)
        }
    }
}
