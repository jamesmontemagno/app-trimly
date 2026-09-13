import SwiftUI

struct RecapCard: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var period: WeightInsights.RecapPeriod = .week
    @State private var showingComparison = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Insights.recapTitle).font(.headline).accessibilityAddTraits(.isHeader)
            Picker(String(localized: L10n.Insights.recapTitle), selection: $period) {
                Text(L10n.Insights.weekly).tag(WeightInsights.RecapPeriod.week)
                Text(L10n.Insights.monthly).tag(WeightInsights.RecapPeriod.month)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text(L10n.Insights.recapTitle))
            if let comparison = WeightInsights.recap(dailyWeights: dataManager.getDailyWeights(), period: period) {
                PeriodComparisonSummary(comparison: comparison)
            }
            Text(L10n.Insights.recapExplanation).font(.caption).foregroundStyle(.secondary)
            Button(String(localized: L10n.Insights.comparePeriods)) { showingComparison = true }
                .frame(minHeight: 44)
                .accessibilityLabel(Text(L10n.Insights.comparePeriods))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingComparison) { PeriodComparisonView() }
    }
}
