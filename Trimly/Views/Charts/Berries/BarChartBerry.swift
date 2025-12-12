//
//  BarChartBerry.swift
//  TrimTally
//
//  Chart Berry #3: Daily bar chart
//

import SwiftUI
import Charts

struct BarChartBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Bar Chart")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				BarMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(
					LinearGradient(
						colors: [.green, .teal],
						startPoint: .top,
						endPoint: .bottom
					)
				)
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
