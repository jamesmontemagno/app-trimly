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
				
				// Show 7-day average if user has at least 7 check-ins
				if let sevenDayAvg = calculateSevenDayAverage() {
					VStack(spacing: 4) {
						Divider()
							.padding(.horizontal, 40)
							.padding(.top, 4)
							.padding(.bottom, 4)
						
						Text(L10n.Dashboard.sevenDayAverage)
							.font(.caption2)
							.foregroundStyle(.secondary)
						
						Text(displayValue(sevenDayAvg))
							.font(.title3.weight(.semibold))
							.foregroundStyle(.blue)
					}
					.padding(.top, 4)
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
	
	private func calculateSevenDayAverage() -> Double? {
		// Get all entries to check if user has at least 7 check-ins
		let allEntries = dataManager.fetchAllEntries().filter { !$0.isHidden }
		guard allEntries.count >= 7 else { return nil }
		
		// Get daily weights and take the last 7 days
		let dailyWeights = dataManager.getDailyWeights()
		guard !dailyWeights.isEmpty else { return nil }
		
		// Take up to the last 7 days (may be fewer if user hasn't logged that long)
		let last7Days = dailyWeights.suffix(7)
		
		// Calculate average of available days
		let sum = last7Days.reduce(0.0) { $0 + $1.weight }
		return sum / Double(last7Days.count)
	}
}
