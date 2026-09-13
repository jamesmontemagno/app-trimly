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
        VStack(alignment: .leading, spacing: 16) {
            ChartSelectionSummary(point: selectedPoint, unit: unit, precision: precision) {
                selectedDate = nil
            }
            baseChart
                .chartXAxis(showsAxes ? .automatic : .hidden)
                .chartYAxis(showsAxes ? .automatic : .hidden)
                .frame(height: 300)
                .accessibilityLabel(Text(L10n.Charts.navigationTitle))
        }
        .animation(reduceMotion ? nil : .easeInOut, value: selectedDate)
    }

    private var baseChart: some View {
        Chart {
            entryMarks
            averageMarks
            goalMarks
            selectionMarks
        }
        .chartForegroundStyleScale([
            weightLabel: weightGradient,
            maLabel: gradient(from: movingAverageColor.opacity(0.9), to: movingAverageColor),
            emaLabel: gradient(from: emaColor.opacity(0.9), to: emaColor)
        ])
        .chartLegend(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let anchor = proxy.plotFrame {
                    let plotFrame = geometry[anchor]
                    ZStack {
                        if let point = selectedPoint, let x = proxy.position(forX: point.date) {
                            Rectangle()
                                .fill(weightLinePrimary.opacity(0.08))
                                .frame(width: max(24, plotFrame.width * 0.015), height: plotFrame.height)
                                .position(x: x + plotFrame.minX, y: plotFrame.midY)
                                .allowsHitTesting(false)
                        }
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .frame(width: plotFrame.width, height: plotFrame.height)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // This gesture is local to the plot, not the surrounding axes.
                                        let x = min(max(value.location.x, 0), plotFrame.width)
                                        if let date: Date = proxy.value(atX: x) {
                                            selectedDate = ChartDataPoint.nearest(to: date, in: data)?.date
                                        }
                                    }
                            )
                            .position(x: plotFrame.midX, y: plotFrame.midY)
                    }
                    .accessibilityHidden(true)
                }
            }
        }
    }

    @ChartContentBuilder
    private var entryMarks: some ChartContent {
        ForEach(data) { point in
            if data.count > 1 {
                LineMark(x: .value(dateLabel, point.date), y: .value(weightLabel, convert(point.weight)))
                    .foregroundStyle(by: .value(seriesLabel, weightLabel))
                    .interpolationMethod(.monotone)
            }
            if selectedDate != nil || data.count == 1 {
                PointMark(x: .value(dateLabel, point.date), y: .value(weightLabel, convert(point.weight)))
                    .foregroundStyle(by: .value(seriesLabel, weightLabel))
                    .symbol { pointSymbol(for: point) }
                    .accessibilityLabel(Text(point.date, format: .dateTime.day().month().year()))
                    .accessibilityValue(Text(InsightFormatting.weight(point.weight, unit: unit)))
            }
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
    }

    @ChartContentBuilder
    private var averageMarks: some ChartContent {
        ForEach(movingAverage) { point in
            LineMark(x: .value(dateLabel, point.date), y: .value(maLabel, convert(point.weight)))
                .foregroundStyle(by: .value(seriesLabel, maLabel))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .interpolationMethod(.monotone)
        }
        ForEach(ema) { point in
            LineMark(x: .value(dateLabel, point.date), y: .value(emaLabel, convert(point.weight)))
                .foregroundStyle(by: .value(seriesLabel, emaLabel))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
                .interpolationMethod(.monotone)
        }
    }

    @ChartContentBuilder
    private var goalMarks: some ChartContent {
        if let goal = dataManager.fetchActiveGoal(), convert(goal.targetWeightKg).isFinite, goal.targetWeightKg > 0 {
            RuleMark(y: .value(goalLabel, convert(goal.targetWeightKg)))
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L10n.Charts.goalLabel).font(.caption).foregroundStyle(.green)
                }
            if let first = data.first, let last = data.last,
               goal.startDate >= first.date, goal.startDate <= last.date {
                RuleMark(x: .value(String(localized: L10n.Insights.sinceGoal), goal.startDate))
                    .foregroundStyle(.purple.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
    }

    @ChartContentBuilder
    private var selectionMarks: some ChartContent {
        if let point = selectedPoint {
            RuleMark(x: .value(dateLabel, point.date))
                .foregroundStyle(weightLinePrimary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
        }
    }

    private func pointSymbol(for point: ChartDataPoint) -> some View {
        let isSelected = point.date == selectedDate
        return Circle()
            .strokeBorder(weightLinePrimary, lineWidth: isSelected ? 3 : 2)
            .background(Circle().fill(isSelected ? pointFillColor : weightLineSecondary))
            .frame(width: isSelected ? 24 : 12, height: isSelected ? 24 : 12)
    }

    private var unit: WeightUnit { dataManager.settings?.preferredUnit ?? .kilograms }
    private var precision: Int { dataManager.settings?.decimalPrecision ?? 1 }
    private var showsAxes: Bool { dataManager.settings?.chartMode == .analytical }

    private var selectedPoint: ChartDataPoint? {
        guard let selectedDate else { return nil }
        return ChartDataPoint.nearest(to: selectedDate, in: data)
    }

    private var weightLinePrimary: Color { Color(red: 0.31, green: 0.55, blue: 1.0) }
    private var weightLineSecondary: Color { Color(red: 0.29, green: 0.78, blue: 1.0) }
    private var movingAverageColor: Color { Color(red: 0.99, green: 0.64, blue: 0.32) }
    private var emaColor: Color { Color(red: 0.74, green: 0.54, blue: 0.96) }
    private var weightGradient: LinearGradient { gradient(from: weightLinePrimary, to: weightLineSecondary) }
    private func gradient(from start: Color, to end: Color) -> LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .leading, endPoint: .trailing)
    }
    private var pointFillColor: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    private func convert(_ kg: Double) -> Double { unit.convert(fromKg: kg) }
    private var dateLabel: String { String(localized: L10n.Insights.dateAxis) }
    private var weightLabel: String { String(localized: L10n.Charts.legendWeight) }
    private var seriesLabel: String { String(localized: L10n.Insights.seriesAxis) }
    private var maLabel: String { String(localized: L10n.Charts.legendMovingAverage) }
    private var emaLabel: String { String(localized: L10n.Charts.legendEMA) }
    private var goalLabel: String { String(localized: L10n.Charts.goalLabel) }
}
