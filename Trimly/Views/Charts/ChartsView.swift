//
//  ChartsView.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
import Charts
import Combine
#if os(macOS)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct ChartsView: View {
	@EnvironmentObject var dataManager: DataManager
	@State private var selectedRange: ChartRange = .week
	@State private var showingSettings = false
	@State private var showingAddEntry = false
	@State private var selectedPoint: ChartDataPoint?
	@State private var showingMAInfo = false
	@State private var showingEMAInfo = false
	@State private var showDots = false
	@State private var chartCache: [ChartRange: [ChartDataPoint]] = [:]
	@State private var movingAverageCache: [ChartRange: [ChartDataPoint]] = [:]
	@State private var emaCache: [ChartRange: [ChartDataPoint]] = [:]
	private let minimumHighlightBandWidth: CGFloat = 24 // Keep the selection band visible on tight plots.
	private let highlightBandWidthPercentage: CGFloat = 0.015 // Scale the selection band with the plot width.

	private let tooltipFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				Picker(String(localized: L10n.Charts.rangePicker), selection: $selectedRange) {
					ForEach(ChartRange.allCases, id: \.self) { range in
						Text(range.displayName).tag(range)
					}
				}
				.pickerStyle(.segmented)
				.padding()
				
				ScrollView {
					VStack(spacing: 16) {
						if let chartData = chartData {
							weightChart(data: chartData)
								.padding()
						} else {
							ContentUnavailableView(
								String(localized: L10n.Charts.noDataTitle),
								systemImage: "chart.xyaxis.line",
								description: Text(L10n.Charts.noDataDescription)
							)
						}
					}
				}
			}
			.navigationTitle(Text(L10n.Charts.navigationTitle))
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showingAddEntry = true
					} label: {
						Image(systemName: "plus")
					}
					.accessibilityLabel(Text(L10n.Common.addWeight))
				}
				#if os(iOS)
				ToolbarItem(placement: .topBarLeading) {
					Button {
						showingSettings = true
					} label: {
						Image(systemName: "slider.horizontal.3")
					}
					.accessibilityLabel(Text(L10n.Charts.settingsButton))
				}
				#else
				ToolbarItem(placement: .navigation) {
					Button {
						showingSettings = true
					} label: {
						Image(systemName: "slider.horizontal.3")
					}
					.accessibilityLabel(Text(L10n.Charts.settingsButton))
				}
				#endif
			}
			.sheet(isPresented: $showingAddEntry) {
				AddWeightEntryView()
			}
			.sheet(isPresented: $showingSettings) {
				ChartSettingsView()
			}
		}
		.onChange(of: selectedRange) { _, _ in
			selectedPoint = nil
			showDots = false
			prewarmCaches(for: selectedRange)
		}
		.onReceive(dataManager.objectWillChange) { _ in
			invalidateCaches()
			prewarmCaches(for: selectedRange)
		}
		.onAppear {
			prewarmCaches(for: selectedRange)
		}
	}
	
	@ViewBuilder
	private func weightChart(data: [ChartDataPoint]) -> some View {
		let chartMode = dataManager.settings?.chartMode ?? .minimalist
		
		VStack(alignment: .leading, spacing: 16) {
			Group {
				if let selectedPoint {
					selectionSummaryView(for: selectedPoint)
						.transition(.opacity.combined(with: .move(edge: .top)))
				} else {
					selectionHintView
				}
			}
			.animation(.easeInOut, value: selectedPoint?.id)

			Chart {
				weightSeriesMarks(data: data)
				selectedPointRuleMark()
				movingAverageMarks()
				emaMarks()
				goalMarks(data: data)
			}
			.frame(height: 300)
			.chartXAxis(chartMode == .minimalist ? .hidden : .automatic)
			.chartYAxis(chartMode == .minimalist ? .hidden : .automatic)
			.chartYScale(domain: .automatic(includesZero: false))
			.chartForegroundStyleScale([
				ChartSeries.weight.rawValue: weightLineGradient,
				ChartSeries.movingAverage.rawValue: movingAverageGradient,
				ChartSeries.ema.rawValue: emaLineGradient
			])
			.chartLegend(.hidden)
			.chartOverlay { proxy in
				GeometryReader { geo in
					ZStack {
						if let selectedPoint,
						   let plotFrameAnchor = proxy.plotFrame,
						   let xPosition = proxy.position(forX: selectedPoint.date) {
							let plotFrame = geo[plotFrameAnchor]
							let highlightX = xPosition + plotFrame.origin.x
							let bandWidth = highlightBandWidth(for: plotFrame)
							
							Rectangle()
								.fill(weightLinePrimary.opacity(0.08))
								.frame(width: bandWidth, height: plotFrame.height)
								.position(x: highlightX, y: plotFrame.midY)
								.allowsHitTesting(false)
						}
						
						Rectangle()
							.fill(.clear)
							.contentShape(Rectangle())
							.gesture(
								DragGesture(minimumDistance: 0)
									.onChanged { value in
										updateSelection(at: value.location, proxy: proxy, geometry: geo, data: data)
									}
									.onEnded { _ in }
							)
							.onTapGesture { location in
								updateSelection(at: location, proxy: proxy, geometry: geo, data: data)
							}
					}
				}
			}
			
			if dataManager.settings?.showMovingAverage == true || dataManager.settings?.showEMA == true {
				ChartLegend(
					showMovingAverage: dataManager.settings?.showMovingAverage == true,
					showEMA: dataManager.settings?.showEMA == true,
					onMAInfo: { showingMAInfo = true },
					onEMAInfo: { showingEMAInfo = true }
				)
			}
			
			if let stats = calculateStats(data: data) {
				AnalyticsDashboardView(stats: stats, data: data, range: selectedRange)
			}
		}
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.alert(String(localized: L10n.Charts.maInfoTitle), isPresented: $showingMAInfo) {
			Button(String(localized: L10n.Common.okButton), role: .cancel) {}
		} message: {
			Text(L10n.Charts.maInfoDescription)
		}
		.alert(String(localized: L10n.Charts.emaInfoTitle), isPresented: $showingEMAInfo) {
			Button(String(localized: L10n.Common.okButton), role: .cancel) {}
		} message: {
			Text(L10n.Charts.emaInfoDescription)
		}
	}
	
	// MARK: - Data Processing
	
	private var chartData: [ChartDataPoint]? {
		cachedChartData(for: selectedRange)
	}
	
	private var movingAverageData: [ChartDataPoint]? {
		cachedMovingAverageData(for: selectedRange)
	}
	
	private var emaData: [ChartDataPoint]? {
		cachedEMAData(for: selectedRange)
	}
	
	private func cachedChartData(for range: ChartRange) -> [ChartDataPoint]? {
		if let cached = chartCache[range] {
			return cached
		}
		
		let dailyWeights = dataManager.getDailyWeights()
		guard !dailyWeights.isEmpty else { return nil }
		
		let filtered = filterData(dailyWeights, in: range)
		guard !filtered.isEmpty else { return nil }
		
		let mapped = filtered.map { ChartDataPoint(date: $0.date, weight: $0.weight) }
		chartCache[range] = mapped
		return mapped
	}
	
	private func cachedMovingAverageData(for range: ChartRange) -> [ChartDataPoint]? {
		if let cached = movingAverageCache[range] {
			return cached.isEmpty ? nil : cached
		}
		
		guard let period = dataManager.settings?.movingAveragePeriod else { return nil }
		let dailyWeights = dataManager.getDailyWeights()
		let filtered = filterData(dailyWeights, in: range)
		
		let ma = WeightAnalytics.calculateMovingAverage(dailyWeights: filtered, period: period)
		let mapped = ma.map { ChartDataPoint(date: $0.date, weight: $0.value) }
		guard !mapped.isEmpty else { return nil }
		movingAverageCache[range] = mapped
		return mapped
	}
	
	private func cachedEMAData(for range: ChartRange) -> [ChartDataPoint]? {
		if let cached = emaCache[range] {
			return cached.isEmpty ? nil : cached
		}
		
		guard let period = dataManager.settings?.emaPeriod else { return nil }
		let dailyWeights = dataManager.getDailyWeights()
		let filtered = filterData(dailyWeights, in: range)
		
		let ema = WeightAnalytics.calculateEMA(dailyWeights: filtered, period: period)
		let mapped = ema.map { ChartDataPoint(date: $0.date, weight: $0.value) }
		guard !mapped.isEmpty else { return nil }
		emaCache[range] = mapped
		return mapped
	}
	
	private func filterData(_ data: [(date: Date, weight: Double)], in range: ChartRange) -> [(date: Date, weight: Double)] {
		let calendar = Calendar.current
		let now = Date()
		
		let startDate: Date
		switch range {
		case .week:
			startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
		case .month:
			startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
		case .quarter:
			startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
		case .year:
			startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
		}
		
		return data.filter { $0.date >= startDate }
	}
	
	private func calculateStats(data: [ChartDataPoint]) -> ChartStats? {
		guard !data.isEmpty else { return nil }
		
		let weights = data.map { $0.weight }
		let min = weights.min() ?? 0
		let max = weights.max() ?? 0
		let average = weights.reduce(0, +) / Double(weights.count)
		
		return ChartStats(min: min, max: max, average: average, range: max - min)
	}
	
	// MARK: - Helpers
	
	private func invalidateCaches() {
		chartCache.removeAll()
		movingAverageCache.removeAll()
		emaCache.removeAll()
	}
	
	private func prewarmCaches(for range: ChartRange) {
		_ = cachedChartData(for: range)
		if dataManager.settings?.showMovingAverage == true {
			_ = cachedMovingAverageData(for: range)
		}
		if dataManager.settings?.showEMA == true {
			_ = cachedEMAData(for: range)
		}
	}

	private func highlightBandWidth(for plotFrame: CGRect) -> CGFloat {
		max(minimumHighlightBandWidth, plotFrame.width * highlightBandWidthPercentage)
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f", kg)
		}
		
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f", precision, value)
	}

	private func convertedWeight(_ kg: Double) -> Double {
		guard let unit = dataManager.settings?.preferredUnit else { return kg }
		return unit.convert(fromKg: kg)
	}

	@ViewBuilder
	private func selectionSummaryView(for point: ChartDataPoint) -> some View {
		let unitSymbol = dataManager.settings?.preferredUnit.symbol ?? "kg"
		let dateText = tooltipFormatter.string(from: point.date)

		HStack(alignment: .top) {
			VStack(alignment: .leading, spacing: 4) {
				Text(L10n.Charts.selectionTitle)
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(dateText)
					.font(.headline)
			}
			Spacer()
			Text("\(displayValue(point.weight)) \(unitSymbol)")
				.font(.title3.weight(.semibold))
				.multilineTextAlignment(.trailing)
		}
		.padding(12)
		.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
		.accessibilityElement(children: .combine)
		.accessibilityLabel(Text("\(dateText), \(displayValue(point.weight)) \(unitSymbol)"))
		.onTapGesture {
			// Tapping the selected summary hides the dots
			withAnimation {
				showDots = false
				selectedPoint = nil
			}
		}
	}

	private var selectionHintView: some View {
		HStack(spacing: 8) {
			Image(systemName: "hand.tap")
				.font(.subheadline)
				.foregroundStyle(.secondary)
			Text(showDots ? L10n.Charts.selectionHint : L10n.Charts.tapToShowDotsHint)
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
		.padding(12)
		.background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
	}

	private func pointAccessibilityLabel(_ point: ChartDataPoint) -> Text {
		let dateText = tooltipFormatter.string(from: point.date)
		return Text("\(dateText), \(displayValue(point.weight)) \(dataManager.settings?.preferredUnit.symbol ?? "kg")")
	}
	
	@ViewBuilder
	private func pointSymbol(for point: ChartDataPoint) -> some View {
		let isSelected = point.id == selectedPoint?.id
		let size: CGFloat = isSelected ? 24 : 12
		Circle()
			.strokeBorder(weightLinePrimary, lineWidth: isSelected ? 3 : 2)
			.background(
				Circle()
					.fill(isSelected ? pointFillColor : weightLineSecondary)
			)
			.frame(width: size, height: size)
	}

	private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy, data: [ChartDataPoint]) {
		guard let plotFrameAnchor = proxy.plotFrame else { return }
		let plotFrame = geometry[plotFrameAnchor]
		let xPosition = location.x - plotFrame.origin.x
		guard xPosition >= 0, xPosition <= plotFrame.size.width else { return }
		
		guard let date: Date = proxy.value(atX: xPosition) else { return }
		if let nearest = nearestPoint(to: date, in: data) {
			withAnimation {
				showDots = true
				selectedPoint = nearest
			}
		}
	}

	private func nearestPoint(to date: Date, in data: [ChartDataPoint]) -> ChartDataPoint? {
		data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
	}
	
	// MARK: - Chart Components
	
	@ChartContentBuilder
	private func weightSeriesMarks(data: [ChartDataPoint]) -> some ChartContent {
		// Draw the line connecting all points (only if more than 1 point)
		if data.count > 1 {
			ForEach(data) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("Weight", convertedWeight(point.weight))
				)
				.foregroundStyle(by: .value("Series", ChartSeries.weight.rawValue))
				.interpolationMethod(.monotone)
			}
		}
		
		// Draw points if enabled OR if there's only one data point
		if showDots || data.count == 1 {
			ForEach(data) { point in
				PointMark(
					x: .value("Date", point.date),
					y: .value("Weight", convertedWeight(point.weight))
				)
				.symbol {
					pointSymbol(for: point)
				}
				.foregroundStyle(by: .value("Series", ChartSeries.weight.rawValue))
				.accessibilityLabel(pointAccessibilityLabel(point))
			}
		}
	}
	
	@ChartContentBuilder
	private func selectedPointRuleMark() -> some ChartContent {
		if let selectedPoint {
			RuleMark(x: .value("Selected Date", selectedPoint.date))
				.foregroundStyle(weightLinePrimary.opacity(0.3))
				.lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
		}
	}
	
	@ChartContentBuilder
	private func movingAverageMarks() -> some ChartContent {
		if dataManager.settings?.showMovingAverage == true,
		   let maData = movingAverageData {
			ForEach(maData) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("MA", convertedWeight(point.weight))
				)
				.foregroundStyle(by: .value("Series", ChartSeries.movingAverage.rawValue))
				.lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
				.interpolationMethod(.monotone)
			}
		}
	}
	
	@ChartContentBuilder
	private func emaMarks() -> some ChartContent {
		if dataManager.settings?.showEMA == true,
		   let emaData = emaData {
			ForEach(emaData) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("EMA", convertedWeight(point.weight))
				)
				.foregroundStyle(by: .value("Series", ChartSeries.ema.rawValue))
				.lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
				.interpolationMethod(.monotone)
			}
		}
	}
	
	@ChartContentBuilder
	private func goalMarks(data: [ChartDataPoint]) -> some ChartContent {
		if let goal = dataManager.fetchActiveGoal() {
			RuleMark(
				y: .value("Goal", convertedWeight(goal.targetWeightKg))
			)
			.foregroundStyle(goalLineColor)
			.lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
			.annotation(position: .top, alignment: .trailing) {
				Text(L10n.Charts.goalLabel)
					.font(.caption)
					.foregroundStyle(goalLineColor)
			}
			
			// Add goal start date marker as vertical line
			if let startDate = goal.startDate as Date?,
			   startDate >= (data.first?.date ?? Date.distantPast),
			   startDate <= (data.last?.date ?? Date.distantFuture) {
				RuleMark(
					x: .value("Goal Start", startDate)
				)
				.foregroundStyle(.purple.opacity(0.6))
				.lineStyle(StrokeStyle(lineWidth: 2))
			}
		}
	}
	
	// MARK: - Colors
	
	private var weightLinePrimary: Color { Color(red: 0.31, green: 0.55, blue: 1.0) }
	private var weightLineSecondary: Color { Color(red: 0.29, green: 0.78, blue: 1.0) }
	private var weightLineGradient: LinearGradient {
		LinearGradient(colors: [weightLinePrimary, weightLineSecondary], startPoint: .leading, endPoint: .trailing)
	}
	private var movingAverageColor: Color { Color(red: 0.99, green: 0.64, blue: 0.32) }
	private var movingAverageGradient: LinearGradient {
		LinearGradient(colors: [movingAverageColor.opacity(0.9), movingAverageColor], startPoint: .leading, endPoint: .trailing)
	}
	private var emaLineColor: Color { Color(red: 0.74, green: 0.54, blue: 0.96) }
	private var emaLineGradient: LinearGradient {
		LinearGradient(colors: [emaLineColor.opacity(0.9), emaLineColor], startPoint: .leading, endPoint: .trailing)
	}
	private var goalLineColor: Color { .green }
	private var pointFillColor: Color {
#if os(macOS)
		Color(nsColor: .windowBackgroundColor)
#else
		Color(uiColor: .systemBackground)
#endif
	}
}

#Preview {
	ChartsView()
		.environmentObject(DataManager(inMemory: true))
}
