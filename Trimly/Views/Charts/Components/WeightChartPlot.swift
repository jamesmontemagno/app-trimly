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
            if let point = selectedPoint {
                RuleMark(x: .value(dateLabel, point.date))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                    .annotation(position: .top, spacing: 0,
                                overflowResolution: .init(x: .fitToChart, y: .disabled)) {
                        ChartTooltip(point: point, unit: unit, precision: precision, note: nil)
                            .accessibilityHidden(true)
                    }
                PointMark(x: .value(dateLabel, point.date), y: .value(weightLabel, convert(point.weight)))
                    .foregroundStyle(by: .value(seriesLabel, weightLabel))
                    .symbolSize(120)
            }
        }
        .chartForegroundStyleScale([weightLabel: Color.blue, maLabel: Color.orange, emaLabel: Color.purple])
        .chartLegend(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            if showsAxes {
                AxisMarks(preset: .aligned, values: .stride(by: axisStride.component, count: axisStride.count)) { value in
                    AxisGridLine()
                    AxisTick()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: axisFormat)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .chartYAxis(showsAxes ? .automatic : .hidden)
        .chartXSelection(value: persistentSelection)
        .chartGesture { proxy in
            DragGesture(minimumDistance: 8)
                .onChanged { proxy.selectXValue(at: $0.location.x) }
        }
        .chartPlotStyle { plot in
            plot.padding(.horizontal, 8)
        }
        .frame(height: 300)
        .animation(reduceMotion ? nil : .easeInOut, value: selectedDate)
        .accessibilityLabel(Text(L10n.Charts.navigationTitle))
    }

    private var unit: WeightUnit { dataManager.settings?.preferredUnit ?? .kilograms }
    private var precision: Int { dataManager.settings?.decimalPrecision ?? 1 }
    private var showsAxes: Bool { dataManager.settings?.chartMode == .analytical }

    private var selectedPoint: ChartDataPoint? {
        guard let selectedDate else { return nil }
        return data.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }

    /// Number of days covered by the plotted data, used to size the date axis labels.
    private var spanInDays: Int {
        guard let first = data.first?.date, let last = data.last?.date else { return 0 }
        return Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
    }

    /// Spacing between date labels so they never overlap or get truncated.
    private var axisStride: (component: Calendar.Component, count: Int) {
        switch spanInDays {
        case ..<8: return (.day, 1)
        case ..<32: return (.day, 7)
        case ..<100: return (.day, 14)
        case ..<400: return (.month, 2)
        default: return (.month, 6)
        }
    }

    /// Compact date format matched to the visible range.
    private var axisFormat: Date.FormatStyle {
        switch spanInDays {
        case ..<8: return .dateTime.weekday(.abbreviated)
        case ..<100: return .dateTime.month(.abbreviated).day()
        case ..<400: return .dateTime.month(.abbreviated)
        default: return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }

    private var persistentSelection: Binding<Date?> {
        Binding(
            get: { selectedDate },
            set: { proposedDate in
                guard let proposedDate,
                      let nearestDate = data.min(by: {
                          abs($0.date.timeIntervalSince(proposedDate))
                              < abs($1.date.timeIntervalSince(proposedDate))
                      })?.date else {
                    return
                }
                selectedDate = nearestDate
            }
        )
    }

    private func convert(_ kg: Double) -> Double { unit.convert(fromKg: kg) }
    private var dateLabel: String { String(localized: L10n.Insights.dateAxis) }
    private var weightLabel: String { String(localized: L10n.Charts.legendWeight) }
    private var seriesLabel: String { String(localized: L10n.Insights.seriesAxis) }
    private var maLabel: String { String(localized: L10n.Charts.legendMovingAverage) }
    private var emaLabel: String { String(localized: L10n.Charts.legendEMA) }
    private var goalLabel: String { String(localized: L10n.Charts.goalLabel) }
}
