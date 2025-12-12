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
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Bubble Density")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			Chart(data) { point in
				// Light connection line
				LineMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
				)
				.foregroundStyle(.gray.opacity(0.2))
				.interpolationMethod(.catmullRom)
				.lineStyle(StrokeStyle(lineWidth: 1))
				
				// Bubble points
				PointMark(
					x: .value("Date", point.date),
					y: .value("Weight", unit.convert(fromKg: point.weight))
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
			.frame(height: 200)
			.chartXAxis(.hidden)
			.chartYAxis(.hidden)
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
