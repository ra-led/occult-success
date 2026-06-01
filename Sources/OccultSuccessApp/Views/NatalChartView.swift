import SwiftUI

struct NatalChartView: View {
    @EnvironmentObject private var appState: AppState
    @State private var input = NatalChartInput()

    var body: some View {
        NavigationStack {
            Form {
                Section("Данные рождения") {
                    TextField("Имя", text: $input.name)
                    DatePicker("Дата и время", selection: $input.birthDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Место рождения", text: $input.birthPlace)
                    Button("Рассчитать натальную карту") {
                        appState.calculateNatalChart(input: input)
                    }
                }

                if let chart = appState.natalChart {
                    Section(chart.name) {
                        LabeledContent("Солнце", value: chart.sunSign.rawValue)
                        LabeledContent("Луна", value: chart.moonSign.rawValue)
                        LabeledContent("Асцендент", value: chart.ascendant.rawValue)
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
}
