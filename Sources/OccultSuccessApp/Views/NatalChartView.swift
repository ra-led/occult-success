import MapKit
import SwiftUI

struct NatalChartView: View {
    @EnvironmentObject private var appState: AppState
    @State private var input = NatalChartInput()
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
            span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
        )
    )

    private let locationSearch = BirthLocationSearchService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Данные рождения") {
                    TextField("Имя", text: $input.name)
                    DatePicker("Дата и время", selection: $input.birthDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Город рождения", text: $input.birthPlace)
                    Picker("Система домов", selection: $input.houseSystem) {
                        ForEach(HouseSystem.allCases) { system in
                            Text(system.rawValue).tag(system)
                        }
                    }
                    Button {
                        Task { await searchBirthPlace() }
                    } label: {
                        if isSearching {
                            ProgressView()
                        } else {
                            Label("Найти город на карте", systemImage: "location.magnifyingglass")
                        }
                    }
                    .disabled(isSearching)

                    if let searchError {
                        Text(searchError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if let location = input.birthLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(location.title)
                                .font(.headline)
                            if !location.subtitle.isEmpty {
                                Text(location.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Text(location.coordinateSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Map(position: $mapPosition) {
                                Marker(
                                    location.title,
                                    coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                )
                                .tint(.purple)
                            }
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    Button("Рассчитать натальную карту") {
                        Task { await calculateChart() }
                    }
                }
                .onChange(of: input.birthPlace) { _, _ in
                    input.birthLocation = nil
                }

                if let chart = appState.natalChart {
                    Section {
                        NatalChartWheelView(chart: chart)
                            .frame(height: 360)
                            .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
                    }

                    Section(chart.name) {
                        if let location = chart.location {
                            LabeledContent("Место", value: location.title)
                        }
                        LabeledContent("Дома", value: chart.houseSystem.rawValue)
                        ForEach(chart.placements) { placement in
                            LabeledContent(placement.body.rawValue, value: placement.formattedPosition)
                        }
                        Text(chart.interpretation)
                    }

                    Section("Дома") {
                        ForEach(chart.houses) { house in
                            Text(house.formattedPosition)
                        }
                    }

                    Section("Аспекты") {
                        if chart.aspects.isEmpty {
                            Text("Мажорных аспектов с орбом до 6° нет.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(chart.aspects.prefix(12)) { aspect in
                                Text(aspect.title)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MysticBackground())
            .navigationTitle("Натальная карта")
        }
    }

    private func searchBirthPlace() async {
        isSearching = true
        defer { isSearching = false }

        do {
            let location = try await locationSearch.searchCity(input.birthPlace)
            input.birthLocation = location
            searchError = nil
            mapPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 1.6, longitudeDelta: 1.6)
                )
            )
        } catch {
            searchError = error.localizedDescription
        }
    }

    private func calculateChart() async {
        if input.birthLocation == nil && !input.birthPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await searchBirthPlace()
        }

        appState.calculateNatalChart(input: input)
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
                                Color.purple.opacity(0.18)
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
                        .stroke(house.number == 1 || house.number == 10 ? .mint.opacity(0.9) : .cyan.opacity(0.45), lineWidth: house.number == 1 || house.number == 10 ? 2.4 : 1.2)
                    Text("\(house.number)")
                        .font(.caption2.bold())
                        .foregroundStyle(.mint)
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
        case .sun: return .yellow
        case .moon: return .white
        case .mercury: return .cyan
        case .venus: return .pink
        case .mars: return .red
        case .jupiter: return .orange
        case .saturn: return .brown
        case .uranus: return .mint
        case .neptune: return .blue
        case .pluto: return .purple
        case .ascendant, .midheaven: return .green
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
        case .conjunction: return .white
        case .sextile: return .mint
        case .square: return .red
        case .trine: return .blue
        case .opposition: return .orange
        }
    }
}
