//
//  StepChartBerry.swift
//  TrimTally
//
//  Chart Berry #9: Step chart with plateau visualization
//

import SwiftUI
import Charts

struct StepChartBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Step Chart")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(.cyan)
				.interpolationMethod(.stepEnd)
				.lineStyle(StrokeStyle(lineWidth: 3))
				
				PointMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(.white)
				.symbolSize(80)
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
