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
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Mountain Ridge")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				// Base layer
				AreaMark(
					x: .value("Date", point.date),
					yStart: .value("Min", minWeight * 0.98),
					yEnd: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(
					LinearGradient(
						colors: [.indigo.opacity(0.4), .indigo.opacity(0.1)],
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.interpolationMethod(.monotone)
				
				// Middle layer
				AreaMark(
					x: .value("Date", point.date),
					yStart: .value("Mid", minWeight * 0.99),
					yEnd: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(
					LinearGradient(
						colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.interpolationMethod(.monotone)
				
				// Top line
				LineMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(.white)
				.lineStyle(StrokeStyle(lineWidth: 2))
				.interpolationMethod(.monotone)
			}
			.frame(height: 200)
			.chartXAxis(.hidden)
			.chartYAxis(.hidden)
			.chartYScale(domain: .automatic(includesZero: false))
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
	
	private var minWeight: Double {
		let weights = data.map { unit.convert(fromKg: $0.weight) }
		return weights.min() ?? 0
	}
}
