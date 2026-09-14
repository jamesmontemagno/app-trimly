import SwiftUI
import Charts

private enum ChartRangeTab: CaseIterable, Hashable {
    case week
    case month
    case quarter
    case year
    case more

    var label: LocalizedStringResource {
        switch self {
        case .week: L10n.Insights.rangeWeekShort
        case .month: L10n.Insights.rangeMonthShort
        case .quarter: L10n.Insights.rangeQuarterShort
        case .year: L10n.Insights.rangeYearShort
        case .more: L10n.Insights.moreRanges
        }
    }
}

struct ChartsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @State private var selectedRange: ChartRange = .week
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd = Date()
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
        .onChange(of: customStart) { _, _ in selectedDate = nil }
        .onChange(of: customEnd) { _, _ in selectedDate = nil }
        .onChange(of: dataManager.dataRevision) { _, _ in selectedDate = nil }
    }

    private var rangeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(String(localized: L10n.Charts.rangePicker), selection: rangeTab) {
                ForEach(ChartRangeTab.allCases, id: \.self) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
            .accessibilityLabel(Text(L10n.Charts.rangePicker))
            if rangeTab.wrappedValue == .more {
                Picker(String(localized: L10n.Insights.moreRanges), selection: $selectedRange) {
                    Text(L10n.Insights.allTime).tag(ChartRange.allTime)
                    Text(L10n.Insights.sinceGoal).tag(ChartRange.sinceGoal)
                    Text(L10n.Insights.customRange).tag(ChartRange.custom)
                }
                .pickerStyle(.menu)
                .frame(minHeight: 44)
                .accessibilityLabel(Text(L10n.Insights.moreRanges))
            }
            if selectedRange == .custom {
                DatePicker(String(localized: L10n.Insights.startDate), selection: $customStart, in: ...Date(), displayedComponents: .date)
                    .accessibilityLabel(Text(L10n.Insights.startDate))
                DatePicker(String(localized: L10n.Insights.endDate), selection: $customEnd, in: ...Date(), displayedComponents: .date)
                    .accessibilityLabel(Text(L10n.Insights.endDate))
            }
        }
    }

    private var rangeTab: Binding<ChartRangeTab> {
        Binding(
            get: {
                switch selectedRange {
                case .week: .week
                case .month: .month
                case .quarter: .quarter
                case .year: .year
                case .allTime, .sinceGoal, .custom: .more
                }
            },
            set: { tab in
                switch tab {
                case .week: selectedRange = .week
                case .month: selectedRange = .month
                case .quarter: selectedRange = .quarter
                case .year: selectedRange = .year
                case .more:
                    if ![.allTime, .sinceGoal, .custom].contains(selectedRange) {
                        selectedRange = .allTime
                    }
                }
            }
        )
    }

    private func chartSection(data: [ChartDataPoint], period: WeightInsights.Period) -> some View {
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
                Text(L10n.Insights.samplesExplanation).font(.caption).foregroundStyle(.secondary)
            }
            if let stats = stats(data) {
                AnalyticsDashboardView(stats: stats, data: data, range: selectedRange, period: period)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .alert(String(localized: L10n.Charts.maInfoTitle), isPresented: $showingMAInfo) {
            Button(String(localized: L10n.Common.okButton), role: .cancel) {}
        } message: {
            Text(L10n.Insights.samplesExplanation)
        }
        .alert(String(localized: L10n.Charts.emaInfoTitle), isPresented: $showingEMAInfo) {
            Button(String(localized: L10n.Common.okButton), role: .cancel) {}
        } message: {
            Text(L10n.Insights.samplesExplanation)
        }
    }

    private var allData: [WeightInsights.DailyWeight] {
        let unit = dataManager.settings?.preferredUnit ?? .kilograms
        return dataManager.getDailyWeights().filter {
            $0.weight.isFinite && $0.weight > 0 && unit.convert(fromKg: $0.weight).isFinite && $0.date <= Date()
        }
    }

    private var period: WeightInsights.Period? {
        selectedRange.period(firstDate: allData.first?.date, goalStart: dataManager.fetchActiveGoal()?.startDate,
                             customStart: customStart, customEnd: customEnd)
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

    private func stats(_ data: [ChartDataPoint]) -> ChartStats? {
        let weights = data.map(\.weight)
        guard let minimum = weights.min(), let maximum = weights.max() else { return nil }
        return ChartStats(min: minimum, max: maximum,
                          average: weights.reduce(0) { $0 + $1 / Double(weights.count) }, range: maximum - minimum)
    }
}

#Preview {
    ChartsView().environmentObject(DataManager(inMemory: true)).environmentObject(DeviceSettingsStore())
}
