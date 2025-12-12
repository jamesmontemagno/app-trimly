//
//  DualAxisBerry.swift
//  TrimTally
//
//  Chart Berry #5: Dual axis showing weight and trend
//

import SwiftUI
import Charts

struct DualAxisBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Dual Axis Trend")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart {
				// Weight line
				ForEach(data) { point in
					LineMark(
						x: .value("Date", point.date),
						y: .value("Weight", unit.convert(fromKg: point.weight))
					)
					.foregroundStyle(.blue)
					.interpolationMethod(.catmullRom)
					.lineStyle(StrokeStyle(lineWidth: 2))
				}
				
				// Trend line (moving average)
				ForEach(movingAverage) { point in
					LineMark(
						x: .value("Date", point.date),
						y: .value("Trend", unit.convert(fromKg: point.weight))
					)
					.foregroundStyle(.orange)
					.interpolationMethod(.catmullRom)
					.lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
				}
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
	
	private var movingAverage: [ChartDataPoint] {
		guard data.count >= 3 else { return [] }
		var result: [ChartDataPoint] = []
		
		for i in 2..<data.count {
			let sum = data[i-2].weight + data[i-1].weight + data[i].weight
			let avg = sum / 3.0
			result.append(ChartDataPoint(date: data[i].date, weight: avg))
		}
		
		return result
	}
}
