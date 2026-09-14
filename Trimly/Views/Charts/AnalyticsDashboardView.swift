import SwiftUI

struct AnalyticsDashboardView: View {
    let data: [ChartDataPoint]
    var period: WeightInsights.Period? = nil
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        let tuples = data.map { (date: $0.date, weight: $0.weight) }
        let support = WeightInsights.support(for: tuples)
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                statisticCards(tuples, support: support)
            }
            InsightSupportView(support: support, showsDetails: false)
        }
    }

    @ViewBuilder
    private func statisticCards(
        _ tuples: [WeightInsights.DailyWeight],
        support: WeightInsights.Support
    ) -> some View {
        FunStatCard(
            icon: "scalemass.fill",
            title: String(localized: L10n.Charts.statLatest),
            value: latest,
            color: .blue
        )
        FunStatCard(
            icon: periodChangeIcon,
            title: String(localized: L10n.Charts.statPeriodChange),
            value: periodChange,
            color: periodChangeColor
        )
        FunStatCard(
            icon: "calendar.badge.clock",
            title: String(localized: L10n.Charts.statPerWeek),
            value: weeklyRate(tuples, support: support),
            color: .purple
        )

        if support.state == .supported {
            let trend = WeightAnalytics.classifyTrend(dailyWeights: tuples)
            FunStatCard(
                icon: trendIcon(trend),
                title: String(localized: L10n.Dashboard.trendTitle),
                value: trend.description,
                color: trendColor(trend)
            )
        }

        if let period {
            let summary = WeightInsights.summarize(tuples, in: period)
            FunStatCard(
                icon: "chart.bar.fill",
                title: String(localized: L10n.Charts.statConsistency),
                value: consistencyPercentage(summary),
                color: .indigo
            )
            FunStatCard(
                icon: "checkmark.circle.fill",
                title: String(localized: L10n.Charts.statCheckIns),
                value: String(localized: L10n.Charts.checkInsValue(summary.loggingDays, summary.calendarDays)),
                color: .blue
            )
        }
    }

    private var periodChangeValue: Double? {
        guard data.count > 1, let first = data.first, let last = data.last else { return nil }
        return last.weight - first.weight
    }

    private var periodChangeIcon: String {
        guard let change = periodChangeValue else { return "equal.circle.fill" }
        if change < 0 { return "arrow.down.right.circle.fill" }
        if change > 0 { return "arrow.up.right.circle.fill" }
        return "equal.circle.fill"
    }

    private var periodChangeColor: Color {
        guard let change = periodChangeValue else { return .secondary }
        if change < 0 { return .green }
        if change > 0 { return .orange }
        return .blue
    }

    private func trendIcon(_ trend: WeightAnalytics.TrendDirection) -> String {
        switch trend {
        case .downward:
            return "chart.line.downtrend.xyaxis"
        case .upward:
            return "chart.line.uptrend.xyaxis"
        case .stable:
            return "arrow.right.circle.fill"
        }
    }

    private func trendColor(_ trend: WeightAnalytics.TrendDirection) -> Color {
        switch trend {
        case .downward:
            return .green
        case .upward:
            return .orange
        case .stable:
            return .blue
        }
    }

    private var latest: String {
        guard let last = data.last else { return placeholder }
        return display(last.weight)
    }

    private var periodChange: String {
        guard let change = periodChangeValue else { return placeholder }
        return display(change, signed: true)
    }

    /// Regression slope communicates direction better than endpoint difference alone.
    private func weeklyRate(_ tuples: [WeightInsights.DailyWeight], support: WeightInsights.Support) -> String {
        guard support.state == .supported,
              let slope = WeightAnalytics.calculateLinearRegression(dailyWeights: tuples).slope,
              (slope * 7).isFinite else { return placeholder }
        return display(slope * 7, signed: true)
    }

    private func consistencyPercentage(_ summary: WeightInsights.PeriodSummary) -> String {
        let ratio = Double(summary.loggingDays) / Double(max(1, summary.calendarDays))
        return ratio.formatted(.percent.precision(.fractionLength(0)))
    }

    private var placeholder: String { String(localized: L10n.Dashboard.placeholder) }

    private func display(_ kg: Double, signed: Bool = false) -> String {
        InsightFormatting.weight(kg, unit: dataManager.settings?.preferredUnit ?? .kilograms,
                                 precision: dataManager.settings?.decimalPrecision ?? 1, signed: signed)
    }
}
