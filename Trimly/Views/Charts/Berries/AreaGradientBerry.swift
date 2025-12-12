//
//  AreaGradientBerry.swift
//  TrimTally
//
//  Chart Berry #2: Filled gradient area chart
//

import SwiftUI
import Charts

struct AreaGradientBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Gradient Area")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				AreaMark(
					x: .value("Date", point.date),
					yStart: .value("Min", minWeight),
					yEnd: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(
					LinearGradient(
						colors: [.purple.opacity(0.6), .blue.opacity(0.3)],
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.interpolationMethod(.catmullRom)
				
				LineMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(.purple)
				.lineStyle(StrokeStyle(lineWidth: 2))
				.interpolationMethod(.catmullRom)
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
