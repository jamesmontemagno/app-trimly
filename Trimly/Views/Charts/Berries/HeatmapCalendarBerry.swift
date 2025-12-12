//
//  HeatmapCalendarBerry.swift
//  TrimTally
//
//  Chart Berry #6: Heatmap calendar grid view
//

import SwiftUI

struct HeatmapCalendarBerry: View {
	let data: [ChartDataPoint]
	let unit: WeightUnit
	
	private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Heatmap Calendar")
				.font(.headline)
				.foregroundStyle(.secondary)
			
			LazyVGrid(columns: columns, spacing: 4) {
				ForEach(heatmapData) { item in
					RoundedRectangle(cornerRadius: 3)
						.fill(item.color)
						.frame(height: 25)
						.overlay {
							if item.hasData {
								Image(systemName: "checkmark")
									.font(.caption2)
									.foregroundStyle(.white)
							}
						}
				}
			}
			.frame(height: 200)
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
	
	private struct HeatmapItem: Identifiable {
		let id = UUID()
		let date: Date
		let hasData: Bool
		let value: Double?
		
		var color: Color {
			guard hasData, let value = value else {
				return Color.gray.opacity(0.1)
			}
			return Color.blue.opacity(0.3 + (value * 0.7))
		}
	}
	
	private var heatmapData: [HeatmapItem] {
		let calendar = Calendar.current
		let endDate = Date()
		let startDate = calendar.date(byAdding: .day, value: -27, to: endDate) ?? endDate
		
		var items: [HeatmapItem] = []
		var currentDate = startDate
		
		let weights = data.map { unit.convert(fromKg: $0.weight) }
		let minWeight = weights.min() ?? 0
		let maxWeight = weights.max() ?? 1
		let range = maxWeight - minWeight
		
		while currentDate <= endDate {
			let dataPoint = data.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
			let normalizedValue = dataPoint.map { (unit.convert(fromKg: $0.weight) - minWeight) / max(range, 1) }
			
			items.append(HeatmapItem(
				date: currentDate,
				hasData: dataPoint != nil,
				value: normalizedValue
			))
			
			currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
		}
		
		return items
	}
}
