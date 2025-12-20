//
//  DashboardView.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
import Charts

struct DashboardView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var celebrationService: CelebrationService
	@StateObject private var plateauService = PlateauDetectionService()
	@State private var showingAddEntry = false
	@State private var recentlySyncedToHealthKit = false
	@State private var recentlySyncedFromICloud = false
	@State private var showingConsistencyInfo = false
	let onShowCharts: () -> Void

	init(onShowCharts: @escaping () -> Void = {}) {
		self.onShowCharts = onShowCharts
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					TodayWeightCard(
						currentWeight: dataManager.getCurrentWeight(),
						todayEntries: todayEntries,
						recentlySyncedFromICloud: recentlySyncedFromICloud,
						recentlySyncedToHealthKit: recentlySyncedToHealthKit
					)
					
					MiniSparklineCard(
						last7DaysData: last7DaysData,
						onTap: onShowCharts
					)
					
					ProgressSummaryCard(
						goal: dataManager.fetchActiveGoal(),
						currentWeight: dataManager.getCurrentWeight(),
						startWeight: dataManager.fetchActiveGoal()?.startingWeightKg ?? dataManager.getStartWeight()
					)

					
					TrendSummaryCard(
						trend: dataManager.getTrend(),
						onTap: onShowCharts
					)
					
					if let projection = dataManager.getGoalProjection() {
						GoalProjectionCard(projectionDate: projection)
					}
					
					if let plateau = plateauService.currentPlateau {
						PlateauCard(
							plateau: plateau,
							onDismiss: { plateauService.dismissPlateau() }
						)
					}
										
					MonthlyCalendarCard(weightMap: dailyDisplayWeights)
					
					if shouldShowConsistency {
						ConsistencyScoreCard(
							showingInfo: $showingConsistencyInfo,
							score: dataManager.getConsistencyScore()
						)
						.alert("Consistency Score", isPresented: $showingConsistencyInfo) {
							Button("OK", role: .cancel) {}
						} message: {
							consistencyInfoMessage(dataManager: dataManager)
						}
					}
				}
				.padding()
			}
			.navigationTitle(Text(L10n.Dashboard.navigationTitle))
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showingAddEntry = true
					} label: {
						Image(systemName: "plus")
					}
				}
			}
			.sheet(isPresented: $showingAddEntry, onDismiss: {
				if let latest = todayEntries?.max(by: { $0.timestamp < $1.timestamp }), latest.source == .healthKit {
					recentlySyncedToHealthKit = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
						recentlySyncedToHealthKit = false
					}
				}
			}) {
				AddWeightEntryView()
			}
			.onAppear {
				handleInitialCloudSyncState()
				plateauService.checkForPlateau(dataManager: dataManager)
			}
			.onChange(of: dataManager.hasFinishedInitialCloudSync) { _, _ in
				handleInitialCloudSyncState()
			}
		}
	}
	
	// MARK: - Helpers
	
	private var todayEntries: [WeightEntry]? {
		let entries = dataManager.fetchEntriesForDate(Date())
		return entries.isEmpty ? nil : entries
	}
	
	private var last7DaysData: [(date: Date, weight: Double)]? {
		let dailyWeights = dataManager.getDailyWeights()
		guard !dailyWeights.isEmpty else { return nil }
		let last7 = dailyWeights.suffix(7)
		return Array(last7)
	}
	
	private var shouldShowConsistency: Bool {
		let entries = dataManager.fetchAllEntries()
		let uniqueDays = Set(entries.map { $0.normalizedDate })
		return uniqueDays.count >= 7
	}
	
	private var dailyDisplayWeights: [Date: String] {
		let dailyData = dataManager.getDailyWeights()
		
		return dailyData.reduce(into: [Date: String]()) { dict, item in
			dict[item.date] = displayValue(item.weight)
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

// MARK: - Extensions

private extension DashboardView {
	func handleInitialCloudSyncState() {
		dataManager.refreshInitialCloudSyncState()
		guard dataManager.hasFinishedInitialCloudSync else { return }
		guard dataManager.hasShownInitialCloudSyncSuccess == false else { return }
		guard dataManager.getCurrentWeight() != nil else { return }
		recentlySyncedFromICloud = true
		dataManager.markInitialCloudSyncSuccessShown()
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
			recentlySyncedFromICloud = false
		}
	}
}

#Preview {
	NavigationStack {
		DashboardView()
			.environmentObject(DataManager(inMemory: true))
			.environmentObject(CelebrationService())
	}
}
