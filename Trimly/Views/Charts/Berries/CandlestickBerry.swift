//
//  CandlestickBerry.swift
//  TrimTally
//
//  Chart Berry #4: Candlestick-style showing daily range
//

import SwiftUI
import Charts

struct CandlestickBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Candlestick Range")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				// Simulated range - in real app would show daily min/max
				let value = unit.convert(fromKg: point.weight)
				let range = value * 0.005 // 0.5% range simulation
				
				RectangleMark(
					x: .value("Date", point.date),
					yStart: .value("Low", value - range),
					yEnd: .value("High", value + range),
					width: .fixed(8)
				)
				.foregroundStyle(.orange.gradient)
				
				PointMark(
					x: .value("Date", point.date),
					y: .value("Weight", value)
				)
				.foregroundStyle(.white)
				.symbolSize(20)
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
