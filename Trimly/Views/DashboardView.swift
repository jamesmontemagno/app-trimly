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
	@StateObject private var celebrationService = CelebrationService()
	@StateObject private var plateauService = PlateauDetectionService()
	@State private var showingAddEntry = false
	@State private var recentlySyncedToHealthKit = false
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					todayWeightCard
					miniSparklineCard
					progressSummaryCard
                    
					if shouldShowConsistency {
						consistencyScoreCard
					}
                    
					trendSummaryCard
                    
					if let projection = dataManager.getGoalProjection() {
						projectionCard(projection)
					}
                    
					if let plateau = plateauService.currentPlateau {
						plateauCard(plateau)
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
			.overlay {
				if let celebration = celebrationService.currentCelebration {
					CelebrationOverlayView(celebration: celebration)
						.transition(.scale.combined(with: .opacity))
						.onTapGesture {
							celebrationService.dismissCelebration()
						}
				}
			}
			.onAppear {
				if let celebration = celebrationService.checkForCelebrations(dataManager: dataManager) {
					celebrationService.showCelebration(celebration)
				}
                
				plateauService.checkForPlateau(dataManager: dataManager)
			}
		}
	}
    
	private var todayWeightCard: some View {
		VStack(spacing: 12) {
			Text(L10n.Dashboard.currentWeight)
				.font(.subheadline)
				.foregroundStyle(.secondary)
            
			if let currentWeight = dataManager.getCurrentWeight() {
				let displayWeight = displayValue(currentWeight)
				Text(displayWeight)
					.font(.system(size: 56, weight: .bold, design: .rounded))
					.contentTransition(.numericText())
                
				if let todayEntries = todayEntries, !todayEntries.isEmpty {
					primaryValueIndicator(entries: todayEntries)
				}
				if recentlySyncedToHealthKit {
					HStack(spacing: 6) {
						Image(systemName: "heart.fill")
							.font(.caption)
							.foregroundStyle(.pink)
						Text(L10n.Dashboard.syncedToHealthKit)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			} else {
				Text(L10n.Dashboard.placeholder)
					.font(.system(size: 56, weight: .bold, design: .rounded))
					.foregroundStyle(.secondary)
                
				Text(L10n.Dashboard.noEntries)
					.font(.caption)
					.foregroundStyle(.tertiary)
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
    
	private var miniSparklineCard: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(L10n.Dashboard.lastSevenDays)
				.font(.subheadline)
				.foregroundStyle(.secondary)
            
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
    
	private var progressSummaryCard: some View {
		VStack(spacing: 12) {
			if let goal = dataManager.fetchActiveGoal(),
			   let currentWeight = dataManager.getCurrentWeight(),
			   let startWeight = goal.startingWeightKg ?? dataManager.getStartWeight() {
				
				HStack(spacing: 20) {
					VStack(alignment: .leading, spacing: 4) {
						Text(L10n.Dashboard.fromStart)
							.font(.caption)
							.foregroundStyle(.secondary)
                        
						let delta = currentWeight - startWeight
						let deltaDisplay = formatDelta(delta)
						Text(deltaDisplay)
							.font(.title3.bold())
							.foregroundStyle(delta < 0 ? .green : delta > 0 ? .orange : .primary)
					}
                    
					Divider()
                    
					VStack(alignment: .leading, spacing: 4) {
						Text(L10n.Dashboard.toGoal)
							.font(.caption)
							.foregroundStyle(.secondary)
                        
						let remaining = currentWeight - goal.targetWeightKg
						let remainingDisplay = formatDelta(abs(remaining))
						Text(remainingDisplay)
							.font(.title3.bold())
							.foregroundStyle(.blue)
					}
                    
					Divider()
                    
					VStack(alignment: .leading, spacing: 4) {
						Text(L10n.Dashboard.progress)
							.font(.caption)
							.foregroundStyle(.secondary)
                        
						let totalChange = goal.targetWeightKg - startWeight
						let currentChange = currentWeight - startWeight
						let progress = totalChange != 0 ? (currentChange / totalChange) * 100 : 0
                        
						Text("\(Int(min(100, max(0, progress))))%")
							.font(.title3.bold())
							.foregroundStyle(.purple)
					}
				}
				.frame(maxWidth: .infinity)
				
				if let goalStartDate = goal.startDate as Date? {
					let startDisplay = displayValue(startWeight)
					let targetDisplay = displayValue(goal.targetWeightKg)
					let dateDisplay = goalStartDate.formatted(date: .abbreviated, time: .omitted)
					
					Divider()
					
					HStack(spacing: 10) {
						Text(String(localized: L10n.Dashboard.progressMetaStart(startDisplay)))
							.font(.caption)
							.foregroundStyle(.secondary)
						Text(String(localized: L10n.Dashboard.progressMetaSeparator))
							.font(.caption)
							.foregroundStyle(.tertiary)
						Text(String(localized: L10n.Dashboard.progressMetaTarget(targetDisplay)))
							.font(.caption)
							.foregroundStyle(.secondary)
						Text(String(localized: L10n.Dashboard.progressMetaSeparator))
							.font(.caption)
							.foregroundStyle(.tertiary)
						Text(String(localized: L10n.Dashboard.progressMetaStartDate(dateDisplay)))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			} else {
				Text(L10n.Dashboard.setGoalPrompt)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
    
	private var shouldShowConsistency: Bool {
		let entries = dataManager.fetchAllEntries()
		let uniqueDays = Set(entries.map { $0.normalizedDate })
		return uniqueDays.count >= 7
	}
    
	private var consistencyScoreCard: some View {
		VStack(spacing: 8) {
			Text(L10n.Dashboard.consistencyScore)
				.font(.subheadline)
				.foregroundStyle(.secondary)
            
			if let score = dataManager.getConsistencyScore() {
				let percentage = Int(score * 100)
				Text("\(percentage)%")
					.font(.system(size: 36, weight: .bold, design: .rounded))
					.foregroundStyle(consistencyColor(score))
                
				Text(consistencyLabel(score))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
    
	private func consistencyColor(_ score: Double) -> Color {
		if score >= 0.85 { return .green }
		if score >= 0.70 { return .blue }
		if score >= 0.50 { return .orange }
		return .red
	}
    
	private func consistencyLabel(_ score: Double) -> String {
		if score >= 0.85 { return String(localized: L10n.Dashboard.consistencyVery) }
		if score >= 0.70 { return String(localized: L10n.Dashboard.consistencyConsistent) }
		if score >= 0.50 { return String(localized: L10n.Dashboard.consistencyModerate) }
		return String(localized: L10n.Dashboard.consistencyBuilding)
	}
    
	private var trendSummaryCard: some View {
		VStack(spacing: 8) {
			Text(L10n.Dashboard.trendTitle)
				.font(.subheadline)
				.foregroundStyle(.secondary)
            
			let trend = dataManager.getTrend()
			Text(trend.description)
				.font(.title3.bold())
				.foregroundStyle(trendColor(trend))
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
    
	private func trendColor(_ trend: WeightAnalytics.TrendDirection) -> Color {
		switch trend {
		case .downward: return .green
		case .upward: return .orange
		case .stable: return .blue
		}
	}
    
	private func projectionCard(_ date: Date) -> some View {
		VStack(spacing: 8) {
			Text(L10n.Dashboard.estimatedGoalDate)
				.font(.subheadline)
				.foregroundStyle(.secondary)
            
			Text(date, style: .date)
				.font(.title3.bold())
				.foregroundStyle(.purple)
            
			let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
			Text(L10n.Dashboard.goalArrival(daysUntil))
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
    
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
    
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
	
	private func formatDelta(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
    
	private func plateauCard(_ plateau: PlateauDetectionService.PlateauDetection) -> some View {
		VStack(spacing: 12) {
			HStack {
				Image(systemName: "info.circle.fill")
					.foregroundStyle(.blue)
                
				Text(L10n.Dashboard.plateauDetected)
					.font(.headline)
                
				Spacer()
                
				Button {
					plateauService.dismissPlateau()
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
				}
			}
            
			Text(plateau.message)
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
            
			Text(plateau.hint)
				.font(.caption)
				.foregroundStyle(.tertiary)
				.multilineTextAlignment(.center)
				.padding(.top, 4)
		}
		.padding()
		.background(.blue.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}

struct CelebrationOverlayView: View {
	let celebration: CelebrationService.Celebration
    
	var body: some View {
		VStack(spacing: 16) {
			if #available(macOS 15.0, *) {
				Image(systemName: celebration.iconName)
					.font(.system(size: 60))
					.foregroundStyle(.yellow)
					.symbolEffect(.bounce)
			} else {
				Image(systemName: celebration.iconName)
					.font(.system(size: 60))
					.foregroundStyle(.yellow)
			}
            
			Text(celebration.message)
				.font(.title2.bold())
				.multilineTextAlignment(.center)
				.foregroundStyle(.primary)
		}
		.padding(32)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.shadow(radius: 10)
	}
}

struct CelebrationView: View {
	let message: String
    
	var body: some View {
		VStack(spacing: 16) {
			if #available(macOS 15.0, *) {
				Image(systemName: "star.fill")
					.font(.system(size: 60))
					.foregroundStyle(.yellow)
					.symbolEffect(.bounce)
			} else {
				Image(systemName: "star.fill")
					.font(.system(size: 60))
					.foregroundStyle(.yellow)
			}
            
			Text(message)
				.font(.title2.bold())
				.multilineTextAlignment(.center)
				.foregroundStyle(.primary)
		}
		.padding(32)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.shadow(radius: 10)
	}
}

#Preview {
	NavigationStack {
		DashboardView()
			.environmentObject(DataManager(inMemory: true))
	}
}
