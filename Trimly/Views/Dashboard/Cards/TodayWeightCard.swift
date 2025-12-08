//
//  TodayWeightCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct TodayWeightCard: View {
	@EnvironmentObject var dataManager: DataManager
	let currentWeight: Double?
	let todayEntries: [WeightEntry]?
	let recentlySyncedFromICloud: Bool
	let recentlySyncedToHealthKit: Bool
	
	var body: some View {
		VStack(spacing: 12) {
			Text(L10n.Dashboard.currentWeight)
				.font(.subheadline)
				.foregroundStyle(.secondary)
			
			if let currentWeight {
				let displayWeight = displayValue(currentWeight)
				Text(displayWeight)
					.font(.system(size: 56, weight: .bold, design: .rounded))
					.contentTransition(.numericText())
				
				if let todayEntries, !todayEntries.isEmpty {
					primaryValueIndicator(entries: todayEntries)
				}
				if recentlySyncedFromICloud {
					SyncIndicator(type: .iCloud)
				}
				if recentlySyncedToHealthKit {
					SyncIndicator(type: .healthKit)
				}
			} else {
				Text(L10n.Dashboard.placeholder)
					.font(.system(size: 56, weight: .bold, design: .rounded))
					.foregroundStyle(.secondary)
				
				if dataManager.isAwaitingInitialCloudSync {
					Text(L10n.Dashboard.icloudSyncLoading)
						.font(.caption)
						.foregroundStyle(.secondary)
				} else {
					Text(L10n.Dashboard.noEntries)
						.font(.caption)
						.foregroundStyle(.tertiary)
				}
			}
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
	
	private func primaryValueIndicator(entries: [WeightEntry]) -> some View {
		Group {
			if let mode = dataManager.settings?.dailyAggregationMode {
				switch mode {
				case .latest:
					if let latest = entries.max(by: { $0.timestamp < $1.timestamp }) {
						Text(L10n.Dashboard.latestEntry(latest.timestamp.formatted(date: .omitted, time: .shortened)))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				case .average:
					Text(L10n.Dashboard.averageEntries(entries.count))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}

		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
}
