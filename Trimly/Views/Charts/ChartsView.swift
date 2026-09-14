import SwiftUI
import Charts

struct ChartsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @State private var selectedRange: ChartRange = .week
    @State private var showingSettings = false
    @State private var showingAddEntry = false
    @State private var selectedDate: Date?
    @State private var showingMAInfo = false
    @State private var showingEMAInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if deviceSettings.presentation.hideWeights {
                        ContentUnavailableView(
                            String(localized: L10n.Portability.hideWeights),
                            systemImage: "eye.slash",
                            description: Text(L10n.Portability.hideWeightsHint)
                        )
                    } else {
                    rangeControls
                    if let period {
                        let data = points(in: period)
                        if data.isEmpty {
                            ContentUnavailableView(String(localized: L10n.Charts.noDataTitle),
                                                   systemImage: "chart.xyaxis.line",
                                                   description: Text(L10n.Charts.noDataDescription))
                        } else {
                            Text(L10n.Insights.weightTrend)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityAddTraits(.isHeader)
                            chartSection(data: data, period: period)
                        }
                    } else {
                        Text(selectedRange == .sinceGoal ? L10n.Insights.noGoalRange : L10n.Insights.invalidRange)
                            .foregroundStyle(.secondary)
                    }
                    RecapCard()
                    GoalPaceCard()
                    }
                }
                .padding()
            }
            .navigationTitle(Text(L10n.Charts.navigationTitle))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddEntry = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(Text(L10n.Common.addWeight))
                        .accessibilityHint(Text(L10n.Accessibility.addWeightEntryHint))
                }
                ToolbarItem(placement: .automatic) {
                    Button { showingSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel(Text(L10n.Charts.settingsButton))
                        .accessibilityHint(Text(L10n.Accessibility.opensChartSettings))
                }
            }
            .sheet(isPresented: $showingAddEntry) { AddWeightEntryView() }
            .sheet(isPresented: $showingSettings) { ChartSettingsView() }
        }
        .onChange(of: selectedRange) { _, _ in selectedDate = nil }
        .onChange(of: dataManager.dataRevision) { _, _ in selectedDate = nil }
    }

    private var rangeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(String(localized: L10n.Charts.rangePicker), selection: $selectedRange) {
                ForEach(primaryRanges, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
            .accessibilityLabel(Text(L10n.Charts.rangePicker))
        }
    }

    private var primaryRanges: [ChartRange] {
        [.week, .month, .quarter, .year]
    }

    private func chartSection(data: [ChartDataPoint], period: WeightInsights.Period) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                chartPlot(data: data, period: period)
                    .frame(minWidth: 420, maxWidth: .infinity)
                AnalyticsDashboardView(data: data, period: period)
                    .frame(width: 260)
            }

            VStack(alignment: .leading, spacing: 16) {
                chartPlot(data: data, period: period)
                AnalyticsDashboardView(data: data, period: period)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .alert(String(localized: L10n.Charts.maInfoTitle), isPresented: $showingMAInfo) {
            Button(String(localized: L10n.Common.okButton), role: .cancel) {}
        } message: {
            Text(L10n.Charts.maInfoDescription) + Text(verbatim: "\n\n") + Text(L10n.Insights.samplesExplanation)
        }
        .alert(String(localized: L10n.Charts.emaInfoTitle), isPresented: $showingEMAInfo) {
            Button(String(localized: L10n.Common.okButton), role: .cancel) {}
        } message: {
            Text(L10n.Charts.emaInfoDescription) + Text(verbatim: "\n\n") + Text(L10n.Insights.samplesExplanation)
        }
    }

    private func chartPlot(data: [ChartDataPoint], period: WeightInsights.Period) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            WeightChartPlot(
                data: data, movingAverage: movingAverage(in: period), ema: ema(in: period),
                notesDays: notesDays, range: selectedRange, selectedDate: $selectedDate
            )
            if dataManager.settings?.showMovingAverage == true || dataManager.settings?.showEMA == true {
                ChartLegend(
                    showMovingAverage: dataManager.settings?.showMovingAverage == true,
                    showEMA: dataManager.settings?.showEMA == true,
                    onMAInfo: { showingMAInfo = true }, onEMAInfo: { showingEMAInfo = true }
                )
            }
        }
    }

    private var allData: [WeightInsights.DailyWeight] {
        let unit = dataManager.settings?.preferredUnit ?? .kilograms
        return dataManager.getDailyWeights().filter {
            $0.weight.isFinite && $0.weight > 0 && unit.convert(fromKg: $0.weight).isFinite && $0.date <= Date()
        }
    }

    private var period: WeightInsights.Period? {
        let today = Date()
        return selectedRange.period(
            firstDate: allData.first?.date,
            goalStart: dataManager.fetchActiveGoal()?.startDate,
            customStart: today,
            customEnd: today
        )
    }

    private var notesDays: Set<Date> {
        Set(dataManager.fetchAllEntries().filter {
            !$0.isHidden && !($0.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }.map { WeightEntry.normalizeDate($0.timestamp) })
    }

    private func points(in period: WeightInsights.Period) -> [ChartDataPoint] {
        allData.filter { $0.date >= period.start && $0.date < period.end }
            .map { ChartDataPoint(date: $0.date, weight: $0.weight) }
    }

    private func movingAverage(in period: WeightInsights.Period) -> [ChartDataPoint] {
        guard dataManager.settings?.showMovingAverage == true else { return [] }
        return WeightAnalytics.calculateMovingAverage(dailyWeights: allData, period: dataManager.settings?.movingAveragePeriod ?? 7)
            .filter { $0.date >= period.start && $0.date < period.end }
            .map { ChartDataPoint(date: $0.date, weight: $0.value) }
    }

    private func ema(in period: WeightInsights.Period) -> [ChartDataPoint] {
        guard dataManager.settings?.showEMA == true else { return [] }
        return WeightAnalytics.calculateEMA(dailyWeights: allData, period: dataManager.settings?.emaPeriod ?? 7)
            .filter { $0.date >= period.start && $0.date < period.end }
            .map { ChartDataPoint(date: $0.date, weight: $0.value) }
    }
}

#Preview {
    ChartsView().environmentObject(DataManager(inMemory: true)).environmentObject(DeviceSettingsStore())
}
