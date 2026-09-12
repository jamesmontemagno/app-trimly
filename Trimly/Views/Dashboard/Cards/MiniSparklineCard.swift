//
//  MiniSparklineCard.swift
//  Weigh
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI
import Charts

struct MiniSparklineCard: View {
	@EnvironmentObject private var dataManager: DataManager
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
							.accessibilityHidden(true)
					}
					.foregroundStyle(.secondary)
					
					Spacer()
				}

				if let last7Days = last7DaysData, !last7Days.isEmpty {
					let yDomain = sparklineYDomain(for: last7Days)
					Chart {
						ForEach(last7Days, id: \.date) { data in
							LineMark(
								x: .value(String(localized: L10n.Insights.dateAxis), data.date),
								y: .value(String(localized: L10n.Charts.legendWeight), converted(data.weight))
							)
							.foregroundStyle(.blue.gradient)
							.interpolationMethod(.catmullRom)

							AreaMark(
								x: .value(String(localized: L10n.Insights.dateAxis), data.date),
								y: .value(String(localized: L10n.Charts.legendWeight), converted(data.weight))
							)
							.foregroundStyle(.blue.opacity(0.1).gradient)
							.interpolationMethod(.catmullRom)
							
							PointMark(
								x: .value(String(localized: L10n.Insights.dateAxis), data.date),
								y: .value(String(localized: L10n.Charts.legendWeight), converted(data.weight))
							)
							.symbolSize(30)
							.foregroundStyle(Color.blue)
							.accessibilityLabel(Text(data.date, format: .dateTime.day().month()))
							.accessibilityValue(Text(InsightFormatting.weight(data.weight, unit: dataManager.settings?.preferredUnit ?? .kilograms)))
						}
					}
					.chartXAxis(.hidden)
					.chartYAxis(.hidden)
					.chartYScale(domain: yDomain)
					.frame(height: 80)
				} else {
					Text(L10n.Dashboard.notEnoughData)
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(height: 80)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
		.buttonStyle(.plain)
		.accessibilityLabel(Text(L10n.Dashboard.lastSevenDays))
		.accessibilityHint(Text(L10n.Accessibility.opensCharts))
	}

	private func converted(_ kg: Double) -> Double {
		(dataManager.settings?.preferredUnit ?? .kilograms).convert(fromKg: kg)
	}
	
	private func sparklineYDomain(for data: [(date: Date, weight: Double)]) -> ClosedRange<Double> {
		let weights = data.map { converted($0.weight) }
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
