import SwiftUI

struct GoalPaceCard: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        let pace = WeightInsights.goalPace(goal: dataManager.fetchActiveGoal(), dailyWeights: dataManager.getDailyWeights())
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Insights.paceTitle).font(.headline).accessibilityAddTraits(.isHeader)
            Text(message(pace)).font(.subheadline)
            if let required = pace.requiredKgPerWeek {
                rate(required, title: L10n.Insights.requiredPace)
            }
            if let observed = pace.observedKgPerWeek {
                rate(observed, title: L10n.Insights.observedPace)
            }
            if let days = pace.daysRemaining, days > 0 {
                Text(L10n.Insights.remainingDays(days)).font(.caption)
            }
            Text(L10n.Insights.paceExplanation).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func rate(_ value: Double, title: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            let formatted = InsightFormatting.weight(value, unit: dataManager.settings?.preferredUnit ?? .kilograms,
                                                     precision: dataManager.settings?.decimalPrecision ?? 1, signed: true)
            Text(L10n.Insights.weeklyRate(formatted)).font(.headline)
        }
    }

    private func message(_ pace: WeightInsights.GoalPace) -> LocalizedStringResource {
        switch pace.state {
        case .noGoal: L10n.Insights.noGoal
        case .missingTargetDate: L10n.Insights.missingTargetDate
        case .missingData: L10n.Insights.missingData
        case .achieved: L10n.Insights.achieved
        case .expired: L10n.Insights.expired
        case .insufficient: L10n.Insights.insufficient
        case .sparse: L10n.Insights.sparse
        case .stale: L10n.Insights.stale
        case .available: pace.isOnPace == true ? L10n.Insights.onPace : L10n.Insights.behindPace
        }
    }
}
