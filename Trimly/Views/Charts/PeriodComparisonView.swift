import SwiftUI

struct PeriodComparisonView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var currentStart = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    @State private var currentEnd = Date()
    @State private var previousStart = Calendar.current.date(byAdding: .day, value: -13, to: Date()) ?? Date()
    @State private var previousEnd = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: L10n.Insights.currentPeriod)) {
                    dateFields(start: $currentStart, end: $currentEnd)
                }
                Section(String(localized: L10n.Insights.previousPeriod)) {
                    dateFields(start: $previousStart, end: $previousEnd)
                }
                Section {
                    if deviceSettings.presentation.hideWeights {
                        Text(L10n.Insights.privacyExplanation)
                    } else {
                    if let current = WeightInsights.Period.inclusive(from: currentStart, through: currentEnd),
                       let previous = WeightInsights.Period.inclusive(from: previousStart, through: previousEnd) {
                        PeriodComparisonSummary(comparison: WeightInsights.compare(
                            dailyWeights: dataManager.getDailyWeights(), current: current, previous: previous
                        ))
                    } else {
                        Text(L10n.Insights.invalidRange)
                    }
                    }
                    Text(L10n.Insights.customExplanation)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Text(L10n.Insights.comparePeriodsTitle))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.doneButton)) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
        }
    }

    private func dateFields(start: Binding<Date>, end: Binding<Date>) -> some View {
        Group {
            DatePicker(String(localized: L10n.Insights.startDate), selection: start, in: ...Date(), displayedComponents: .date)
                .accessibilityLabel(Text(L10n.Insights.startDate))
            DatePicker(String(localized: L10n.Insights.endDate), selection: end, in: ...Date(), displayedComponents: .date)
                .accessibilityLabel(Text(L10n.Insights.endDate))
        }
    }
}
