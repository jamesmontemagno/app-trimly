import SwiftUI
import Charts

struct WeightChartPlot: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let data: [ChartDataPoint]
    let movingAverage: [ChartDataPoint]
    let ema: [ChartDataPoint]
    let notesDays: Set<Date>
    @Binding var selectedDate: Date?

    var body: some View {
        Chart {
            ForEach(data) { point in
                if data.count > 1 {
                    LineMark(x: .value(dateLabel, point.date), y: .value(weightLabel, convert(point.weight)))
                        .foregroundStyle(by: .value(seriesLabel, weightLabel))
                        .interpolationMethod(.linear)
                }
                PointMark(x: .value(dateLabel, point.date), y: .value(weightLabel, convert(point.weight)))
                    .foregroundStyle(by: .value(seriesLabel, weightLabel))
                    .symbolSize(notesDays.contains(point.date) ? 65 : 25)
                    .accessibilityLabel(Text(point.date, format: .dateTime.day().month().year()))
                    .accessibilityValue(Text(InsightFormatting.weight(point.weight, unit: unit)))
                if notesDays.contains(point.date) {
                    PointMark(x: .value(dateLabel, point.date), y: .value(weightLabel, convert(point.weight)))
                        .symbol(.square)
                        .foregroundStyle(.primary)
                        .annotation(position: .top) {
                            Image(systemName: "note.text").font(.caption)
                                .accessibilityLabel(Text(L10n.Insights.notes))
                        }
                }
            }
            ForEach(movingAverage) { point in
                LineMark(x: .value(dateLabel, point.date), y: .value(maLabel, convert(point.weight)))
                    .foregroundStyle(by: .value(seriesLabel, maLabel))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            ForEach(ema) { point in
                LineMark(x: .value(dateLabel, point.date), y: .value(emaLabel, convert(point.weight)))
                    .foregroundStyle(by: .value(seriesLabel, emaLabel))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
            }
            if let goal = dataManager.fetchActiveGoal(), convert(goal.targetWeightKg).isFinite, goal.targetWeightKg > 0 {
                RuleMark(y: .value(goalLabel, convert(goal.targetWeightKg)))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(L10n.Charts.goalLabel).font(.caption)
                    }
                if let first = data.first, let last = data.last,
                   goal.startDate >= first.date, goal.startDate <= last.date {
                    RuleMark(x: .value(String(localized: L10n.Insights.sinceGoal), goal.startDate))
                        .foregroundStyle(.purple)
                }
            }
            if let selectedDate, let point = data.min(by: {
                abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
            }) {
                RuleMark(x: .value(dateLabel, point.date))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
            }
        }
        .chartForegroundStyleScale([weightLabel: Color.blue, maLabel: Color.orange, emaLabel: Color.purple])
        .chartLegend(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis(dataManager.settings?.chartMode == .analytical ? .automatic : .hidden)
        .chartYAxis(dataManager.settings?.chartMode == .analytical ? .automatic : .hidden)
        .chartXSelection(value: $selectedDate)
        .frame(height: 300)
        .animation(reduceMotion ? nil : .easeInOut, value: selectedDate)
        .accessibilityLabel(Text(L10n.Charts.navigationTitle))
    }

    private var unit: WeightUnit { dataManager.settings?.preferredUnit ?? .kilograms }
    private func convert(_ kg: Double) -> Double { unit.convert(fromKg: kg) }
    private var dateLabel: String { String(localized: L10n.Insights.dateAxis) }
    private var weightLabel: String { String(localized: L10n.Charts.legendWeight) }
    private var seriesLabel: String { String(localized: L10n.Insights.seriesAxis) }
    private var maLabel: String { String(localized: L10n.Charts.legendMovingAverage) }
    private var emaLabel: String { String(localized: L10n.Charts.legendEMA) }
    private var goalLabel: String { String(localized: L10n.Charts.goalLabel) }
}
