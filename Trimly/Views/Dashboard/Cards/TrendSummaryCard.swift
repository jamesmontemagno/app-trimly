//
//  TrendSummaryCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct TrendSummaryCard: View {
	let trend: WeightAnalytics.TrendDirection
	let onTap: () -> Void
	
	var body: some View {
		Button(action: onTap) {
			VStack(spacing: 8) {
				Text(L10n.Dashboard.trendTitle)
					.font(.subheadline)
					.foregroundStyle(.secondary)
				
				Text(trend.description)
					.font(.title3.bold())
					.foregroundStyle(trendColor(trend))
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
		.buttonStyle(.plain)
		.accessibilityHint(String(localized: L10n.Accessibility.opensCharts))
	}
	
	private func trendColor(_ trend: WeightAnalytics.TrendDirection) -> Color {
		switch trend {
		case .downward: return .green
		case .upward: return .orange
		case .stable: return .blue
		}
	}
}
