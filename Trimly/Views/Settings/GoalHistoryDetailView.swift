import SwiftUI
import Charts

struct GoalHistoryDetailView: View {
    let goal: Goal
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var dailyWeights: [(date: Date, weight: Double)] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if deviceSettings.presentation.hideWeights {
                    Text(L10n.Insights.privacyExplanation)
                } else {
                Section {
                    if let start = goal.startingWeightKg {
                        LabeledContent(String(localized: L10n.Goals.startTitle), value: display(start))
                    }
                    LabeledContent(String(localized: L10n.Goals.targetTitle), value: display(goal.targetWeightKg))
                    if let latest = dailyWeights.last {
                        LabeledContent(String(localized: L10n.EntryFeatures.lastRecorded), value: display(latest.weight))
                    }
                    LabeledContent(String(localized: L10n.EntryFeatures.duration), value: duration.formatted())
                    if let deadline = goal.targetDate {
                        LabeledContent(String(localized: L10n.EntryFeatures.deadline), value: deadline.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                Section {
                    if dailyWeights.isEmpty {
                        Text(L10n.Calendar.noEntry)
                    } else {
                        Chart {
                            ForEach(dailyWeights, id: \.date) { point in
                                LineMark(x: .value(String(localized: L10n.EntryFeatures.day), point.date),
                                         y: .value(unit.symbol, unit.convert(fromKg: point.weight)))
                                PointMark(x: .value(String(localized: L10n.EntryFeatures.day), point.date),
                                          y: .value(unit.symbol, unit.convert(fromKg: point.weight)))
                            }
                            RuleMark(y: .value(unit.symbol, unit.convert(fromKg: goal.targetWeightKg)))
                                .lineStyle(StrokeStyle(dash: [4]))
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 240)
                        .accessibilityLabel(Text(L10n.EntryFeatures.goalHistoryDetail))
                        ForEach(dailyWeights, id: \.date) { point in
                            LabeledContent(point.date.formatted(date: .abbreviated, time: .omitted), value: display(point.weight))
                        }
                    }
                    Text(L10n.EntryFeatures.historyHint)
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let notes = goal.notes, !notes.isEmpty {
                    Section { Text(notes) } header: { Text(L10n.Goals.notesTitle) }
                }
                }
            }
            .navigationTitle(Text(L10n.EntryFeatures.goalHistoryDetail))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.doneButton) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
            .task(id: dataManager.dataRevision) { load() }
            .alert(L10n.Common.errorTitle, isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L10n.Common.okButton, role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var unit: WeightUnit { dataManager.settings?.preferredUnit ?? .kilograms }
    private var duration: Int {
        max(1, (Calendar.current.dateComponents([.day], from: WeightEntry.normalizeDate(goal.startDate),
            to: WeightEntry.normalizeDate(goal.completedDate ?? Date())).day ?? 0) + 1)
    }
    private func display(_ kg: Double) -> String {
        "\(EntryInput.display(unit.convert(fromKg: kg), precision: dataManager.settings?.decimalPrecision ?? 1)) \(unit.symbol)"
    }
    private func load() {
        do {
            let end = max(goal.startDate, goal.completedDate ?? Date()).addingTimeInterval(0.001)
            let entries = try dataManager.fetchEntries(startDate: goal.startDate, endDate: end)
            dailyWeights = WeightAnalytics.aggregateByDay(
                entries: entries, mode: dataManager.settings?.dailyAggregationMode ?? .latest
            ).map { (date: $0.key, weight: $0.value) }.sorted { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
