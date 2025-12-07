//
//  ChartsView.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
import Charts
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
				ForEach(data) { point in
					LineMark(
						x: .value("Date", point.date),
						y: .value("Weight", convertedWeight(point.weight))
					)
					.foregroundStyle(by: .value("Series", ChartSeries.weight.rawValue))
					.interpolationMethod(.monotone)
                    
					PointMark(
						x: .value("Date", point.date),
						y: .value("Weight", convertedWeight(point.weight))
					)
					.symbol {
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
					.foregroundStyle(by: .value("Series", ChartSeries.weight.rawValue))
					.accessibilityLabel(pointAccessibilityLabel(point))
					.annotation(position: .top, alignment: .leading) {
						if selectedPoint?.id == point.id {
							tooltip(for: point)
						}
					}
				}

				if let selectedPoint {
					RuleMark(x: .value("Selected Date", selectedPoint.date))
						.foregroundStyle(weightLinePrimary.opacity(0.3))
						.lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
				}
                
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
				}
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
            
			if dataManager.settings?.showMovingAverage == true || dataManager.settings?.showEMA == true {
				legend
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
    
	private var legend: some View {
		HStack(spacing: 16) {
			LegendItem(color: weightLinePrimary, label: String(localized: L10n.Charts.legendWeight), style: .solid)
            
			if dataManager.settings?.showMovingAverage == true {
				legendItemWithInfo(
					color: movingAverageColor,
					label: String(localized: L10n.Charts.legendMovingAverage),
					style: .dashed,
					onInfo: { showingMAInfo = true }
				)
			}
            
			if dataManager.settings?.showEMA == true {
				legendItemWithInfo(
					color: emaLineColor,
					label: String(localized: L10n.Charts.legendEMA),
					style: .dotted,
					onInfo: { showingEMAInfo = true }
				)
			}
		}
		.font(.caption)
	}

	private func legendItemWithInfo(color: Color, label: String, style: LineStyle, onInfo: @escaping () -> Void) -> some View {
		HStack(spacing: 6) {
			LegendItem(color: color, label: label, style: style)
			Button(action: onInfo) {
				Image(systemName: "info.circle")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.accessibilityLabel(Text(label))
			.accessibilityHint(Text(L10n.Charts.legendInfoHint))
		}
	}
    
	private func statsView(stats: ChartStats) -> some View {
		// Deprecated: Replaced by AnalyticsDashboardView
		EmptyView()
	}
    
	private var chartData: [ChartDataPoint]? {
		let dailyWeights = dataManager.getDailyWeights()
		guard !dailyWeights.isEmpty else { return nil }
        
		let filtered = filterByRange(dailyWeights)
		guard !filtered.isEmpty else { return nil }
        
		return filtered.map { ChartDataPoint(date: $0.date, weight: $0.weight) }
	}
    
	private var movingAverageData: [ChartDataPoint]? {
		guard let period = dataManager.settings?.movingAveragePeriod else { return nil }
		let dailyWeights = dataManager.getDailyWeights()
		let filtered = filterByRange(dailyWeights)
        
		let ma = WeightAnalytics.calculateMovingAverage(dailyWeights: filtered, period: period)
		return ma.map { ChartDataPoint(date: $0.date, weight: $0.value) }
	}
    
	private var emaData: [ChartDataPoint]? {
		guard let period = dataManager.settings?.emaPeriod else { return nil }
		let dailyWeights = dataManager.getDailyWeights()
		let filtered = filterByRange(dailyWeights)
        
		let ema = WeightAnalytics.calculateEMA(dailyWeights: filtered, period: period)
		return ema.map { ChartDataPoint(date: $0.date, weight: $0.value) }
	}
    
	private func filterByRange(_ data: [(date: Date, weight: Double)]) -> [(date: Date, weight: Double)] {
		let calendar = Calendar.current
		let now = Date()
        
		let startDate: Date
		switch selectedRange {
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
	}

	private var selectionHintView: some View {
		HStack(spacing: 8) {
			Image(systemName: "hand.tap")
				.font(.subheadline)
				.foregroundStyle(.secondary)
			Text(L10n.Charts.selectionHint)
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
		.padding(12)
		.background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
	}

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

	private func tooltip(for point: ChartDataPoint) -> some View {
		let entries = dataManager.fetchEntriesForDate(point.date)
		let note = entries.last?.notes

		return VStack(alignment: .leading, spacing: 4) {
			Text(tooltipFormatter.string(from: point.date))
				.font(.caption2)
				.foregroundStyle(.secondary)
			Text("\(displayValue(point.weight)) \(dataManager.settings?.preferredUnit.symbol ?? "kg")")
				.font(.headline)
			
			if let note = note, !note.isEmpty {
				Divider()
				Text(note)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(3)
					.frame(maxWidth: 200, alignment: .leading)
			}
		}
		.padding(12)
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
		.shadow(radius: 4, y: 2)
	}

	private func pointAccessibilityLabel(_ point: ChartDataPoint) -> Text {
		let dateText = tooltipFormatter.string(from: point.date)
		return Text("\(dateText), \(displayValue(point.weight)) \(dataManager.settings?.preferredUnit.symbol ?? "kg")")
	}

	private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy, data: [ChartDataPoint]) {
		guard let plotFrameAnchor = proxy.plotFrame else { return }
		let plotFrame = geometry[plotFrameAnchor]
		let xPosition = location.x - plotFrame.origin.x
		guard xPosition >= 0, xPosition <= plotFrame.size.width else { return }
		guard let date: Date = proxy.value(atX: xPosition) else { return }
		if let nearest = nearestPoint(to: date, in: data) {
			selectedPoint = nearest
		}
	}

	private func nearestPoint(to date: Date, in data: [ChartDataPoint]) -> ChartDataPoint? {
		data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
	}

	private enum ChartSeries: String {
		case weight
		case movingAverage
		case ema
	}
}

struct AnalyticsDashboardView: View {
	let stats: ChartStats
	let data: [ChartDataPoint]
	let range: ChartRange
	@EnvironmentObject var dataManager: DataManager

	var body: some View {
		VStack(spacing: 16) {
			Divider()
			
			// Row 1: Basic Stats (Min/Max/Avg)
			HStack(spacing: 20) {
				StatItem(label: String(localized: L10n.Charts.statMin), value: displayValue(stats.min), color: .green)
				StatItem(label: String(localized: L10n.Charts.statMax), value: displayValue(stats.max), color: .red)
				StatItem(label: String(localized: L10n.Charts.statAvg), value: displayValue(stats.average), color: .blue)
			}
			
			Divider()
			
			// Row 2: Fun Analytics
			LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
				// Trend
				if let trend = calculateTrend() {
					FunStatCard(
						icon: trend.icon,
						title: String(localized: L10n.Dashboard.trendTitle),
						value: trend.text,
						color: trend.color
					)
				}
				
				// Total Change
				if let change = calculateChange() {
					FunStatCard(
						icon: change.value < 0 ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill",
						title: "Total Change",
						value: change.text,
						color: change.value < 0 ? .green : .red
					)
				}
				
				// Goal Projection
				if let projection = calculateProjection() {
					FunStatCard(
						icon: "calendar.badge.clock",
						title: String(localized: L10n.Dashboard.estimatedGoalDate),
						value: projection,
						color: .purple
					)
				}
				
				// Check-ins
				FunStatCard(
					icon: "checkmark.circle.fill",
					title: "Check-ins",
					value: "\(data.count)",
					color: .blue
				)
				
				// Consistency
				if let consistency = calculateConsistency() {
					FunStatCard(
						icon: "chart.bar.fill",
						title: "Consistency",
						value: consistency,
						color: .indigo
					)
				}
				
				// Range Info
				FunStatCard(
					icon: "calendar",
					title: "Timeframe",
					value: range.displayName,
					color: .orange
				)
			}
		}
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f", kg)
		}
		let value = unit.convert(fromKg: kg)
		return String(format: "%.1f", value)
	}
	
	private func calculateTrend() -> (text: String, icon: String, color: Color)? {
		let tuples = data.map { (date: $0.date, weight: $0.weight) }
		let trend = WeightAnalytics.classifyTrend(dailyWeights: tuples)
		
		switch trend {
		case .downward:
			return (trend.description, "chart.line.downtrend.xyaxis", .green)
		case .upward:
			return (trend.description, "chart.line.uptrend.xyaxis", .red)
		case .stable:
			return (trend.description, "arrow.right", .blue)
		}
	}
	
	private func calculateChange() -> (text: String, value: Double)? {
		guard let first = data.first, let last = data.last else { return nil }
		let diff = last.weight - first.weight
		let absDiff = abs(diff)
		let displayDiff = displayValue(absDiff)
		let sign = diff < 0 ? "-" : "+"
		
		guard let unit = dataManager.settings?.preferredUnit else { return nil }
		return ("\(sign)\(displayDiff) \(unit.symbol)", diff)
	}
	
	private func calculateProjection() -> String? {
		guard let goal = dataManager.fetchActiveGoal() else { return nil }
		let tuples = data.map { (date: $0.date, weight: $0.weight) }
		
		if let date = WeightAnalytics.calculateGoalProjection(
			dailyWeights: tuples,
			targetWeightKg: goal.targetWeightKg
		) {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			formatter.timeStyle = .none
			return formatter.string(from: date)
		}
		return nil
	}
	
	private func calculateConsistency() -> String? {
		let entries = dataManager.fetchAllEntries()
		let windowDays: Int
		
		switch range {
		case .week: windowDays = 7
		case .month: windowDays = 30
		case .quarter: windowDays = 90
		case .year: windowDays = 365
		}
		
		guard let score = WeightAnalytics.calculateConsistencyScore(entries: entries, windowDays: windowDays) else {
			return nil
		}
		
		let percentage = Int(score * 100)
		return "\(percentage)%"
	}
}

struct FunStatCard: View {
	let icon: String
	let title: String
	let value: String
	let color: Color
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.title2)
				.foregroundStyle(color)
				.frame(width: 40, height: 40)
				.background(color.opacity(0.1))
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(1)
				Text(value)
					.font(.subheadline.bold())
					.lineLimit(1)
					.minimumScaleFactor(0.8)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(Color.secondary.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
}

enum ChartRange: String, CaseIterable {
	case week = "Week"
	case month = "Month"
	case quarter = "Quarter"
	case year = "Year"

	var displayName: String {
		switch self {
		case .week:
			return String(localized: L10n.Charts.rangeWeek)
		case .month:
			return String(localized: L10n.Charts.rangeMonth)
		case .quarter:
			return String(localized: L10n.Charts.rangeQuarter)
		case .year:
			return String(localized: L10n.Charts.rangeYear)
		}
	}
}

struct ChartDataPoint: Identifiable {
	let id = UUID()
	let date: Date
	let weight: Double
}

struct ChartStats {
	let min: Double
	let max: Double
	let average: Double
	let range: Double
}

enum LineStyle {
	case solid
	case dashed
	case dotted
}

struct LegendItem: View {
	let color: Color
	let label: String
	let style: LineStyle
    
	var body: some View {
		HStack(spacing: 4) {
			Capsule()
				.stroke(color, style: legendStroke)
				.frame(width: 24, height: 4)
            
			Text(label)
				.foregroundStyle(.secondary)
		}
	}

	private var legendStroke: StrokeStyle {
		switch style {
		case .solid:
			return StrokeStyle(lineWidth: 2)
		case .dashed:
			return StrokeStyle(lineWidth: 2, dash: [5, 3])
		case .dotted:
			return StrokeStyle(lineWidth: 2, dash: [1, 4])
		}
	}
}

struct StatItem: View {
	let label: String
	let value: String
	let color: Color
    
	var body: some View {
		VStack(spacing: 2) {
			Text(label)
				.font(.caption2)
				.foregroundStyle(.secondary)
            
			Text(value)
				.font(.subheadline.bold())
				.foregroundStyle(color)
		}
	}
}

struct ChartSettingsView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					TrimlyCardSection(
						title: String(localized: L10n.ChartSettings.displayModeTitle),
						description: String(localized: L10n.ChartSettings.displayModeDescription),
						style: .popup
					) {
						Picker(String(localized: L10n.ChartSettings.displayModeTitle), selection: binding(\.chartMode)) {
							Text(L10n.ChartSettings.displayMinimalist).tag(ChartMode.minimalist)
							Text(L10n.ChartSettings.displayAnalytical).tag(ChartMode.analytical)
						}
						.pickerStyle(.segmented)
					}

					TrimlyCardSection(
						title: String(localized: L10n.ChartSettings.trendLayersTitle),
						description: String(localized: L10n.ChartSettings.trendLayersDescription),
						style: .popup
					) {
						Toggle(L10n.ChartSettings.movingAverageToggle, isOn: binding(\.showMovingAverage))
						Text(L10n.ChartSettings.movingAverageInfo)
							.font(.caption)
							.foregroundStyle(.secondary)

						if dataManager.settings?.showMovingAverage == true {
							Divider().padding(.vertical, 10)
							Stepper(value: binding(\.movingAveragePeriod), in: 3...30) {
								VStack(alignment: .leading, spacing: 2) {
									Label(String(localized: L10n.ChartSettings.movingAverageLabel), systemImage: "chart.xyaxis.line")
										.font(.subheadline.weight(.semibold))
									Text(L10n.ChartSettings.daysLabel(dataManager.settings?.movingAveragePeriod ?? 7))
										.font(.caption)
										.foregroundStyle(.secondary)
								}
							}
						}

						Divider().padding(.vertical, 10)

						Toggle(L10n.ChartSettings.emaToggle, isOn: binding(\.showEMA))
						Text(L10n.ChartSettings.emaInfo)
							.font(.caption)
							.foregroundStyle(.secondary)

						if dataManager.settings?.showEMA == true {
							Divider().padding(.vertical, 10)
							Stepper(value: binding(\.emaPeriod), in: 3...30) {
								VStack(alignment: .leading, spacing: 2) {
									Label(String(localized: L10n.ChartSettings.emaLabel), systemImage: "chart.line.flattrend.xyaxis")
										.font(.subheadline.weight(.semibold))
									Text(L10n.ChartSettings.daysLabel(dataManager.settings?.emaPeriod ?? 7))
										.font(.caption)
										.foregroundStyle(.secondary)
								}
							}
						}

						Text(L10n.ChartSettings.overlaysHint)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
				.padding(24)
			}
			.navigationTitle(Text(L10n.ChartSettings.navigationTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.doneButton)) {
						dismiss()
					}
				}
			}
		}
	}
    
	private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
		Binding(
			get: { dataManager.settings?[keyPath: keyPath] ?? AppSettings()[keyPath: keyPath] },
			set: { newValue in
				dataManager.updateSettings { settings in
					settings[keyPath: keyPath] = newValue
				}
			}
		)
	}
}

#Preview {
	ChartsView()
		.environmentObject(DataManager(inMemory: true))
}
