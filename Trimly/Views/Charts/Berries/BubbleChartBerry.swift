//
//  BubbleChartBerry.swift
//  TrimTally
//
//  Chart Berry #10: Bubble chart where size represents data density
//

import SwiftUI
import Charts

struct BubbleChartBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	let maData: [ChartDataPoint]?
	let emaData: [ChartDataPoint]?
	let goal: Goal?
	let convertWeight: (Double) -> Double
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Bubble Density")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart {
				// Light connection line
				ForEach(data) { point in
					LineMark(
						x: .value("Date", point.date),
						y: .value("Weight", convertWeight(point.weight))
					)
					.foregroundStyle(.gray.opacity(0.2))
					.interpolationMethod(.catmullRom)
					.lineStyle(StrokeStyle(lineWidth: 1))
					
					// Bubble points
					PointMark(
						x: .value("Date", point.date),
						y: .value("Weight", convertWeight(point.weight))
					)
					.foregroundStyle(
						LinearGradient(
							colors: [.pink, .purple],
							startPoint: .top,
							endPoint: .bottom
						)
					)
					.symbolSize(bubbleSize(for: point))
				}
				
				// Moving Average
				if let maData = maData {
					ForEach(maData) { point in
						LineMark(
							x: .value("Date", point.date),
							y: .value("MA", convertWeight(point.weight))
						)
						.foregroundStyle(.orange)
						.lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
						.interpolationMethod(.catmullRom)
					}
				}
				
				// EMA
				if let emaData = emaData {
					ForEach(emaData) { point in
						LineMark(
							x: .value("Date", point.date),
							y: .value("EMA", convertWeight(point.weight))
						)
						.foregroundStyle(.blue)
						.lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
						.interpolationMethod(.catmullRom)
					}
				}
				
				// Goal line and start date
				if let goal = goal {
					RuleMark(
						y: .value("Goal", convertWeight(goal.targetWeightKg))
					)
					.foregroundStyle(.green)
					.lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
					
					if let startDate = goal.startDate as Date?,
					   startDate >= (data.first?.date ?? Date.distantPast),
					   startDate <= (data.last?.date ?? Date.distantFuture) {
						RuleMark(
							x: .value("Goal Start", startDate)
						)
						.foregroundStyle(.green.opacity(0.6))
						.lineStyle(StrokeStyle(lineWidth: 2))
					}
				}
			}
			.frame(height: 300)
			.chartYScale(domain: .automatic(includesZero: false))
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
	
	private func bubbleSize(for point: ChartDataPoint) -> CGFloat {
		// Size based on position in dataset (simulating density/importance)
		let index = data.firstIndex { $0.id == point.id } ?? 0
		let normalized = Double(index) / Double(max(data.count - 1, 1))
		return 50 + (normalized * 150) // Range from 50 to 200
	}
}
