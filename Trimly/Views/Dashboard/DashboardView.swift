//
//  DashboardView.swift
//  Weigh
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
import Charts

struct DashboardView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var celebrationService: CelebrationService
	@EnvironmentObject private var deviceSettings: DeviceSettingsStore
	@Environment(\.scenePhase) private var scenePhase
	@StateObject private var plateauService = PlateauDetectionService()
	@State private var showingAddEntry = false
	@State private var recentlySyncedToHealthKit = false
	@State private var recentlySyncedFromICloud = false
	@State private var showingConsistencyInfo = false
	@State private var showingCustomization = false
	@State private var showingShareCheckIn = false
	let onShowCharts: () -> Void

	init(onShowCharts: @escaping () -> Void = {}) {
		self.onShowCharts = onShowCharts
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					if deviceSettings.presentation.hideWeights {
						Text(L10n.Insights.privacyExplanation)
							.font(.caption).foregroundStyle(.secondary)
					}
					if deviceSettings.presentation.dashboardCards.isEmpty {
						Text(L10n.Insights.noCards).foregroundStyle(.secondary)
					}
					ForEach(deviceSettings.presentation.dashboardCards) { card in
						if deviceSettings.presentation.hideWeights && card != .consistency {
							privacyPlaceholder(for: card)
						} else {
							dashboardCard(card)
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
					.accessibilityLabel(Text(L10n.Common.addWeight))
					.accessibilityHint(Text(L10n.Accessibility.addWeightEntryHint))
				}
				ToolbarItem(placement: .automatic) {
					Button { showingCustomization = true } label: {
						Image(systemName: "slider.horizontal.3")
					}
					.accessibilityLabel(Text(L10n.Insights.customize))
				}
				ToolbarItem(placement: .automatic) {
					Button { showingShareCheckIn = true } label: {
						Image(systemName: "square.and.arrow.up")
					}
					.accessibilityLabel(Text(L10n.Portability.shareCheckIn))
				}
			}
			.sheet(isPresented: $showingCustomization) { PresentationSettingsView() }
			.sheet(isPresented: $showingShareCheckIn) { ShareCheckInView() }
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
			.onChange(of: dataManager.dataRevision) { _, _ in
				plateauService.checkForPlateau(dataManager: dataManager)
			}
			.onChange(of: scenePhase) { _, phase in
				if phase == .active { plateauService.checkForPlateau(dataManager: dataManager) }
			}
		}
	}
	
	// MARK: - Helpers

	@ViewBuilder
	private func dashboardCard(_ card: DashboardCard) -> some View {
		switch card {
		case .today:
			TodayWeightCard(currentWeight: dataManager.getCurrentWeight(), todayEntries: todayEntries,
							recentlySyncedFromICloud: recentlySyncedFromICloud, recentlySyncedToHealthKit: recentlySyncedToHealthKit)
		case .progress:
			ProgressSummaryCard(goal: dataManager.fetchActiveGoal(), currentWeight: dataManager.getCurrentWeight(),
								startWeight: dataManager.fetchActiveGoal()?.startingWeightKg ?? dataManager.getStartWeight())
		case .sparkline:
			MiniSparklineCard(last7DaysData: last7DaysData, onTap: onShowCharts)
		case .consistency:
			if shouldShowConsistency {
				ConsistencyScoreCard(showingInfo: $showingConsistencyInfo, score: dataManager.getConsistencyScore())
					.alert(String(localized: L10n.Dashboard.consistencyScoreAlertTitle), isPresented: $showingConsistencyInfo) {
						Button(String(localized: L10n.Common.okButton), role: .cancel) {}
					} message: { consistencyInfoMessage(dataManager: dataManager) }
			}
		case .trend:
			let recent = dataManager.getDailyWeights().filter {
				$0.date >= (Calendar.current.date(byAdding: .day, value: -27, to: Calendar.current.startOfDay(for: Date())) ?? Date())
			}
			let support = WeightInsights.support(for: recent)
			if support.state == .supported {
				TrendSummaryCard(trend: WeightAnalytics.classifyTrend(dailyWeights: recent), onTap: onShowCharts)
			} else {
				VStack(alignment: .leading, spacing: 8) {
					Text(L10n.Dashboard.trendTitle).font(.headline).accessibilityAddTraits(.isHeader)
					InsightSupportView(support: support)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
			}
		case .calendar:
			MonthlyCalendarCard(weightMap: dailyDisplayWeights)
		case .plateau:
			if let plateau = plateauService.currentPlateau {
				PlateauCard(plateau: plateau, onDismiss: { plateauService.dismissPlateau() })
			}
		case .projection:
			GoalPaceCard()
			if let projection = dataManager.getGoalProjection(), !isGoalAchieved {
				GoalProjectionCard(projectionDate: projection)
			}
		case .recap:
			RecapCard()
		}
	}

	private func privacyPlaceholder(for card: DashboardCard) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(card.title).font(.headline).accessibilityAddTraits(.isHeader)
			Label(String(localized: L10n.Insights.privacyTitle), systemImage: "eye.slash")
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
		.accessibilityElement(children: .combine)
	}
	
	private var todayEntries: [WeightEntry]? {
		let entries = dataManager.fetchEntriesForDate(Date())
		return entries.isEmpty ? nil : entries
	}
	
	private var last7DaysData: [(date: Date, weight: Double)]? {
		let dailyWeights = dataManager.getDailyWeights()
		guard !dailyWeights.isEmpty else { return nil }
		let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date())) ?? Date()
		let last7 = dailyWeights.filter { $0.date >= cutoff && $0.date <= Date() }
		return Array(last7)
	}
	
	private var shouldShowConsistency: Bool {
		let entries = dataManager.fetchAllEntries().filter { !$0.isHidden }
		let uniqueDays = Set(entries.map { WeightEntry.normalizeDate($0.timestamp) })
		return uniqueDays.count >= 7
	}
	
	private var dailyDisplayWeights: [Date: String] {
		let dailyData = dataManager.getDailyWeights()
		
		return dailyData.reduce(into: [Date: String]()) { dict, item in
			dict[item.date] = displayValue(item.weight)
		}
	}
	
	private var isGoalAchieved: Bool {
		guard let goal = dataManager.fetchActiveGoal() else {
			return false
		}
		
		return goal.completionReason == .achieved
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
			.environmentObject(DeviceSettingsStore())
	}
}
