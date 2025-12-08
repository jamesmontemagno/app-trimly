//
//  ChartTooltip.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct ChartTooltip: View {
	let point: ChartDataPoint
	let unit: WeightUnit
	let precision: Int
	let note: String?
	
	private let tooltipFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(tooltipFormatter.string(from: point.date))
				.font(.caption2)
				.foregroundStyle(.secondary)
			Text("\(displayValue(point.weight)) \(unit.symbol)")
				.font(.headline)
			
			if let note = note, !note.isEmpty {
				Divider()
				Text(note)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(3)
					.frame(maxWidth: 200, alignment: .leading)
			}
		}
		.padding(12)
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
		.shadow(radius: 4, y: 2)
	}
	
	private func displayValue(_ kg: Double) -> String {
		let value = unit.convert(fromKg: kg)
		return String(format: "%.*f", precision, value)
	}
}
