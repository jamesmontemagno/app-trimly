//
//  MiniSparklineCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI
import Charts

struct MiniSparklineCard: View {
	let last7DaysData: [(date: Date, weight: Double)]?
	let onTap: () -> Void
	
	var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: 8) {
				HStack {
					HStack(spacing: 6) {
						Text(L10n.Dashboard.lastSevenDays)
							.font(.subheadline)
						Image(systemName: "arrow.up.right.square")
							.font(.caption2)
					}
					.foregroundStyle(.secondary)
					
					Spacer()
				}

				if let last7Days = last7DaysData, !last7Days.isEmpty {
					let yDomain = sparklineYDomain(for: last7Days)
					Chart {
						ForEach(last7Days, id: \.date) { data in
							LineMark(
								x: .value("Date", data.date),
								y: .value("Weight", data.weight)
							)
							.foregroundStyle(.blue.gradient)
							.interpolationMethod(.catmullRom)

							AreaMark(
								x: .value("Date", data.date),
								y: .value("Weight", data.weight)
							)
							.foregroundStyle(.blue.opacity(0.1).gradient)
							.interpolationMethod(.catmullRom)
							
							PointMark(
								x: .value("Date", data.date),
								y: .value("Weight", data.weight)
							)
							.symbolSize(30)
							.foregroundStyle(Color.blue)
						}
					}
					.chartXAxis(.hidden)
					.chartYAxis(.hidden)
					.chartYScale(domain: yDomain)
					.frame(height: 80)
				} else {
					Text(L10n.Dashboard.notEnoughData)
						.font(.caption)
						.foregroundStyle(.tertiary)
						.frame(height: 80)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
		.buttonStyle(.plain)
	}
	
	private func sparklineYDomain(for data: [(date: Date, weight: Double)]) -> ClosedRange<Double> {
		let weights = data.map { $0.weight }
		guard let minWeight = weights.min(), let maxWeight = weights.max() else {
			return 0...1
		}
		if minWeight == maxWeight {
			let padding = max(0.25, minWeight * 0.01)
			return (minWeight - padding)...(maxWeight + padding)
		}
		let padding = max((maxWeight - minWeight) * 0.1, 0.05)
		return (minWeight - padding)...(maxWeight + padding)
	}
}
