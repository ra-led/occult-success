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
                    Section(chart.name) {
                        if let location = chart.location {
                            LabeledContent("Место", value: location.title)
                        }
                        ForEach(chart.placements) { placement in
                            LabeledContent(placement.bodyName, value: placement.formattedPosition)
                        }
                        Text(chart.interpretation)
                    }

                    Section("Дома") {
                        ForEach(chart.houses, id: \.self) { house in
                            Text(house)
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
