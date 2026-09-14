import SwiftUI

enum InsightFormatting {
    static func weight(_ kg: Double, unit: WeightUnit, precision: Int = 1, signed: Bool = false) -> String {
        let value = unit.convert(fromKg: kg)
        guard value.isFinite else { return String(localized: L10n.Dashboard.placeholder) }
        let precision = min(3, max(0, precision))
        let number = signed
            ? value.formatted(.number.precision(.fractionLength(precision)).sign(strategy: .always()))
            : value.formatted(.number.precision(.fractionLength(precision)))
        return "\(number) \(unit.symbol)"
    }
}

struct InsightSupportView: View {
    let support: WeightInsights.Support
    var showsDetails: Bool = true

    var body: some View {
        if showsDetails || message != nil {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let message {
                Label(String(localized: message), systemImage: "info.circle")
            }
            if showsDetails {
                Text(L10n.Insights.supportCounts(support.loggingDays, support.calendarDays))
                Text(L10n.Insights.supportExplanation)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private var message: LocalizedStringResource? {
        switch support.state {
        case .insufficient: L10n.Insights.insufficient
        case .sparse: L10n.Insights.sparse
        case .stale: L10n.Insights.stale
        case .supported: nil
        }
    }
}

struct PeriodComparisonSummary: View {
    @EnvironmentObject private var dataManager: DataManager
    let comparison: WeightInsights.Comparison

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            summary(comparison.current, title: L10n.Insights.currentPeriod)
            summary(comparison.previous, title: L10n.Insights.previousPeriod)
            Divider()
            if let difference = comparison.averageDifferenceKg {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Insights.averageDifference).font(.subheadline)
                    Label(weight(difference, signed: true), systemImage: difference < 0 ? "arrow.down" : difference > 0 ? "arrow.up" : "equal")
                        .font(.headline)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text(L10n.Insights.unavailableComparison).foregroundStyle(.secondary)
            }
        }
    }

    private func summary(_ summary: WeightInsights.PeriodSummary, title: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            let inclusiveEnd = Calendar.current.date(byAdding: .day, value: -1, to: summary.period.end) ?? summary.period.start
            Text(summary.period.start...inclusiveEnd)
                .font(.caption).foregroundStyle(.secondary)
            if let average = summary.averageKg {
                LabeledContent(String(localized: L10n.Charts.statAverageWeight), value: weight(average))
            } else {
                Text(L10n.Insights.noMeasurements).foregroundStyle(.secondary)
            }
            Text(L10n.Insights.coverage(summary.loggingDays, summary.calendarDays))
                .font(.caption)
        }
        .accessibilityElement(children: .combine)
    }

    private func weight(_ kg: Double, signed: Bool = false) -> String {
        InsightFormatting.weight(kg, unit: dataManager.settings?.preferredUnit ?? .kilograms,
                                 precision: dataManager.settings?.decimalPrecision ?? 1, signed: signed)
    }
}
