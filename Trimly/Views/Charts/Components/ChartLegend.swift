//
//  ChartLegend.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct ChartLegend: View {
	let showMovingAverage: Bool
	let showEMA: Bool
	let onMAInfo: () -> Void
	let onEMAInfo: () -> Void
	
	var body: some View {
		HStack(spacing: 16) {
			LegendItem(color: weightLinePrimary, label: String(localized: L10n.Charts.legendWeight), style: .solid)
			
			if showMovingAverage {
				legendItemWithInfo(
					color: movingAverageColor,
					label: String(localized: L10n.Charts.legendMovingAverage),
					style: .dashed,
					onInfo: onMAInfo
				)
			}
			
			if showEMA {
				legendItemWithInfo(
					color: emaLineColor,
					label: String(localized: L10n.Charts.legendEMA),
					style: .dotted,
					onInfo: onEMAInfo
				)
			}
		}
		.font(.caption)
	}
	
	private func legendItemWithInfo(color: Color, label: String, style: LineStyle, onInfo: @escaping () -> Void) -> some View {
		HStack(spacing: 6) {
			LegendItem(color: color, label: label, style: style)
			Button(action: onInfo) {
				Image(systemName: "info.circle")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.accessibilityLabel(Text(label))
			.accessibilityHint(Text(L10n.Charts.legendInfoHint))
		}
	}
	
	private var weightLinePrimary: Color { Color(red: 0.31, green: 0.55, blue: 1.0) }
	private var movingAverageColor: Color { Color(red: 0.99, green: 0.64, blue: 0.32) }
	private var emaLineColor: Color { Color(red: 0.74, green: 0.54, blue: 0.96) }
}
