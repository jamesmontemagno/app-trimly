//
//  DotMatrixBerry.swift
//  TrimTally
//
//  Chart Berry #8: Scatter plot with dot matrix
//

import SwiftUI
import Charts

struct DotMatrixBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Dot Matrix")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				PointMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(colorForWeight(point.weight))
				.symbolSize(150)
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
	
	private func colorForWeight(_ weight: Double) -> Color {
		let weights = data.map { $0.weight }
		guard let min = weights.min(), let max = weights.max() else {
			return .blue
		}
		
		let range = max - min
		guard range > 0 else { return .blue }
		
		let normalized = (weight - min) / range
		
		if normalized < 0.33 {
			return .green
		} else if normalized < 0.66 {
			return .yellow
		} else {
			return .red
		}
	}
}
