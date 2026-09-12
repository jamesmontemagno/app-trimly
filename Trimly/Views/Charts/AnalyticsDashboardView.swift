import SwiftUI

struct AnalyticsDashboardView: View {
    let stats: ChartStats
    let data: [ChartDataPoint]
    let range: ChartRange
    var period: WeightInsights.Period? = nil
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        let tuples = data.map { (date: $0.date, weight: $0.weight) }
        let support = WeightInsights.support(for: tuples)
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { statistics }
                VStack(alignment: .leading, spacing: 12) { statistics }
            }
            if support.state == .supported {
                LabeledContent(String(localized: L10n.Dashboard.trendTitle),
                               value: WeightAnalytics.classifyTrend(dailyWeights: tuples).description)
            }
            InsightSupportView(support: support)
            if let first = data.first, let last = data.last, data.count > 1 {
                LabeledContent(String(localized: L10n.Charts.statTotalChange), value: display(last.weight - first.weight, signed: true))
            }
            LabeledContent(String(localized: L10n.Insights.loggingDays), value: data.count.formatted())
            if let period {
                let summary = WeightInsights.summarize(tuples, in: period)
                LabeledContent(String(localized: L10n.Charts.statConsistency),
                               value: (Double(summary.loggingDays) / Double(max(1, summary.calendarDays))).formatted(.percent.precision(.fractionLength(0))))
                Text(L10n.Insights.coverage(summary.loggingDays, summary.calendarDays))
                    .font(.caption)
            }
            LabeledContent(String(localized: L10n.Charts.statTimeframe), value: range.displayName)
        }
    }

    private var statistics: some View {
        Group {
            StatItem(label: String(localized: L10n.Charts.statMin), value: display(stats.min), color: .primary)
            StatItem(label: String(localized: L10n.Charts.statMax), value: display(stats.max), color: .primary)
            StatItem(label: String(localized: L10n.Charts.statAvg), value: display(stats.average), color: .primary)
        }
    }

    private func display(_ kg: Double, signed: Bool = false) -> String {
        InsightFormatting.weight(kg, unit: dataManager.settings?.preferredUnit ?? .kilograms,
                                 precision: dataManager.settings?.decimalPrecision ?? 1, signed: signed)
    }
}
