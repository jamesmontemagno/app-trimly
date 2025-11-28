//
//  ChartsView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
import Charts

struct ChartsView: View {
	@EnvironmentObject var dataManager: DataManager
	@State private var selectedRange: ChartRange = .week
	@State private var showingSettings = false
    
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				Picker("Range", selection: $selectedRange) {
					ForEach(ChartRange.allCases, id: \.self) { range in
						Text(range.rawValue).tag(range)
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
								"No Data",
								systemImage: "chart.xyaxis.line",
								description: Text("Add weight entries to see your chart")
							)
						}
					}
				}
			}
			.navigationTitle("Charts")
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showingSettings = true
					} label: {
						Image(systemName: "slider.horizontal.3")
					}
				}
			}
			.sheet(isPresented: $showingSettings) {
				ChartSettingsView()
			}
		}
	}
    
	@ViewBuilder
	private func weightChart(data: [ChartDataPoint]) -> some View {
		let chartMode = dataManager.settings?.chartMode ?? .minimalist
        
		VStack(alignment: .leading, spacing: 16) {
			Chart {
				ForEach(data) { point in
					LineMark(
						x: .value("Date", point.date),
						y: .value("Weight", point.weight)
					)
					.foregroundStyle(.blue)
					.interpolationMethod(.catmullRom)
                    
					if chartMode == .analytical {
						PointMark(
							x: .value("Date", point.date),
							y: .value("Weight", point.weight)
						)
						.foregroundStyle(.blue)
					}
				}
                
				if dataManager.settings?.showMovingAverage == true,
				   let maData = movingAverageData {
					ForEach(maData) { point in
						LineMark(
							x: .value("Date", point.date),
							y: .value("MA", point.weight)
						)
						.foregroundStyle(.orange)
						.lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
						.interpolationMethod(.catmullRom)
					}
				}
                
				if dataManager.settings?.showEMA == true,
				   let emaData = emaData {
					ForEach(emaData) { point in
						LineMark(
							x: .value("Date", point.date),
							y: .value("EMA", point.weight)
						)
						.foregroundStyle(.purple)
						.lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
						.interpolationMethod(.catmullRom)
					}
				}
                
				if let goal = dataManager.fetchActiveGoal() {
					RuleMark(
						y: .value("Goal", goal.targetWeightKg)
					)
					.foregroundStyle(.green)
					.lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
					.annotation(position: .top, alignment: .trailing) {
						Text("Goal")
							.font(.caption)
							.foregroundStyle(.green)
							.padding(4)
							.background(.thinMaterial)
							.clipShape(Capsule())
					}
				}
			}
			.frame(height: 300)
			.chartXAxis(chartMode == .minimalist ? .hidden : .automatic)
			.chartYAxis(chartMode == .minimalist ? .hidden : .automatic)
            
			if dataManager.settings?.showMovingAverage == true || dataManager.settings?.showEMA == true {
				legend
			}
            
			if let stats = calculateStats(data: data) {
				statsView(stats: stats)
			}
		}
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
    
	private var legend: some View {
		HStack(spacing: 16) {
			LegendItem(color: .blue, label: "Weight", style: .solid)
            
			if dataManager.settings?.showMovingAverage == true {
				LegendItem(color: .orange, label: "MA", style: .dashed)
			}
            
			if dataManager.settings?.showEMA == true {
				LegendItem(color: .purple, label: "EMA", style: .dotted)
			}
		}
		.font(.caption)
	}
    
	private func statsView(stats: ChartStats) -> some View {
		VStack(spacing: 8) {
			Divider()
            
			HStack(spacing: 20) {
				StatItem(label: "Min", value: displayValue(stats.min), color: .green)
				StatItem(label: "Max", value: displayValue(stats.max), color: .red)
				StatItem(label: "Avg", value: displayValue(stats.average), color: .blue)
				StatItem(label: "Range", value: displayValue(stats.range), color: .orange)
			}
		}
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
}

enum ChartRange: String, CaseIterable {
	case week = "Week"
	case month = "Month"
	case quarter = "Quarter"
	case year = "Year"
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
			Rectangle()
				.fill(color)
				.frame(width: 20, height: 2)
            
			Text(label)
				.foregroundStyle(.secondary)
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
			Form {
				Section {
					Picker("Display Mode", selection: binding(\.chartMode)) {
						Text("Minimalist").tag(ChartMode.minimalist)
						Text("Analytical").tag(ChartMode.analytical)
					}
				}
                
				Section {
					Toggle("Show Moving Average", isOn: binding(\.showMovingAverage))
                    
					if dataManager.settings?.showMovingAverage == true {
						Stepper("Period: \(dataManager.settings?.movingAveragePeriod ?? 7) days",
								value: binding(\.movingAveragePeriod),
								in: 3...30)
					}
                    
					Toggle("Show EMA", isOn: binding(\.showEMA))
                    
					if dataManager.settings?.showEMA == true {
						Stepper("Period: \(dataManager.settings?.emaPeriod ?? 7) days",
								value: binding(\.emaPeriod),
								in: 3...30)
					}
				}
			}
			.navigationTitle("Chart Settings")
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") {
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
