//
//  MinimalistLineBerry.swift
//  TrimTally
//
//  Chart Berry #1: Clean single line chart with minimal styling
//

import SwiftUI
import Charts

struct MinimalistLineBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Minimalist Line")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(.blue)
				.interpolationMethod(.catmullRom)
				.lineStyle(StrokeStyle(lineWidth: 2))
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
}
