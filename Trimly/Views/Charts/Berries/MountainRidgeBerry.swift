//
//  MountainRidgeBerry.swift
//  TrimTally
//
//  Chart Berry #7: Mountain ridge with stacked areas
//

import SwiftUI
import Charts

struct MountainRidgeBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	let maData: [ChartDataPoint]?
	let emaData: [ChartDataPoint]?
	let goal: Goal?
	let convertWeight: (Double) -> Double
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Mountain Ridge")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart {
				// Base layer
				ForEach(data) { point in
					AreaMark(
						x: .value("Date", point.date),
						yStart: .value("Min", minWeight * 0.98),
						yEnd: .value("Weight", convertWeight(point.weight))
					)
					.foregroundStyle(
						LinearGradient(
							colors: [.indigo.opacity(0.4), .indigo.opacity(0.1)],
							startPoint: .top,
							endPoint: .bottom
						)
					)
					.interpolationMethod(.monotone)
					
					// Top line
					LineMark(
						x: .value("Date", point.date),
						y: .value("Weight", convertWeight(point.weight))
					)
					.foregroundStyle(.white)
					.lineStyle(StrokeStyle(lineWidth: 2))
					.interpolationMethod(.monotone)
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
						.foregroundStyle(.purple)
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
	
	private var minWeight: Double {
		let weights = data.map { convertWeight($0.weight) }
		return weights.min() ?? 0
	}
}
