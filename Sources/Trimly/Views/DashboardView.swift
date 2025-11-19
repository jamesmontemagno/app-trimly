//
//  DashboardView.swift
//  Trimly
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
    @State private var showingCelebration = false
    @State private var celebrationMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Weight Card
                    todayWeightCard
                    
                    // Mini Sparkline (Last 7 Days)
                    miniSparklineCard
                    
                    // Progress Summary
                    progressSummaryCard
                    
                    // Consistency Score
                    if shouldShowConsistency {
                        consistencyScoreCard
                    }
                    
                    // Trend Summary
                    trendSummaryCard
                    
                     // Goal Projection
                    if let projection = dataManager.getGoalProjection() {
                        projectionCard(projection)
                    }
                    
                    // Plateau Detection
                    if let plateau = plateauService.currentPlateau {
                        plateauCard(plateau)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddWeightEntryView()
            }
            .overlay {
                // Celebration overlay
                if let celebration = celebrationService.currentCelebration {
                    CelebrationOverlayView(celebration: celebration)
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            celebrationService.dismissCelebration()
                        }
                }
            }
            .onAppear {
                // Check for celebrations
                if let celebration = celebrationService.checkForCelebrations(dataManager: dataManager) {
                    celebrationService.showCelebration(celebration)
                }
                
                // Check for plateau
                plateauService.checkForPlateau(dataManager: dataManager)
            }
        }
    }
    
    // MARK: - Today's Weight Card
    
    private var todayWeightCard: some View {
        VStack(spacing: 12) {
            Text("Current Weight")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let currentWeight = dataManager.getCurrentWeight() {
                let displayWeight = displayValue(currentWeight)
                Text(displayWeight)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                
                // Primary value indicator
                if let todayEntries = todayEntries, !todayEntries.isEmpty {
                    primaryValueIndicator(entries: todayEntries)
                }
            } else {
                Text("--")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text("No entries yet")
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
                        Text("Latest: \(latest.timestamp.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case .average:
                    Text("Average of \(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Mini Sparkline
    
    private var miniSparklineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let last7Days = last7DaysData, !last7Days.isEmpty {
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
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 80)
            } else {
                Text("Not enough data")
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
    
    // MARK: - Progress Summary
    
    private var progressSummaryCard: some View {
        VStack(spacing: 12) {
            if let goal = dataManager.fetchActiveGoal(),
               let currentWeight = dataManager.getCurrentWeight(),
               let startWeight = goal.startingWeightKg ?? dataManager.getStartWeight() {
                
                HStack(spacing: 20) {
                    // Delta from start
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From Start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        let delta = currentWeight - startWeight
                        let deltaDisplay = formatDelta(delta)
                        Text(deltaDisplay)
                            .font(.title3.bold())
                            .foregroundStyle(delta < 0 ? .green : delta > 0 ? .orange : .primary)
                    }
                    
                    Divider()
                    
                    // Delta from goal
                    VStack(alignment: .leading, spacing: 4) {
                        Text("To Goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        let remaining = currentWeight - goal.targetWeightKg
                        let remainingDisplay = formatDelta(abs(remaining))
                        Text(remainingDisplay)
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    
                    Divider()
                    
                    // Progress percentage
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
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
            } else {
                Text("Set a goal to track progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Consistency Score
    
    private var shouldShowConsistency: Bool {
        let entries = dataManager.fetchAllEntries()
        let uniqueDays = Set(entries.map { $0.normalizedDate })
        return uniqueDays.count >= 7
    }
    
    private var consistencyScoreCard: some View {
        VStack(spacing: 8) {
            Text("Consistency Score")
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
        if score >= 0.85 { return "Very consistent" }
        if score >= 0.70 { return "Consistent" }
        if score >= 0.50 { return "Moderate" }
        return "Building consistency"
    }
    
    // MARK: - Trend Summary
    
    private var trendSummaryCard: some View {
        VStack(spacing: 8) {
            Text("Trend")
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
    
    // MARK: - Projection Card
    
    private func projectionCard(_ date: Date) -> some View {
        VStack(spacing: 8) {
            Text("Estimated Goal Date")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(date, style: .date)
                .font(.title3.bold())
                .foregroundStyle(.purple)
            
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            Text("in \(daysUntil) days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
    
    private func displayValue(_ kg: Double) -> String {
        guard let unit = dataManager.settings?.preferredUnit else {
            return String(format: "%.1f kg", kg)
        }
        
        let value = unit.convert(fromKg: kg)
        let precision = dataManager.settings?.decimalPrecision ?? 1
        return String(format: "%.\(precision)f \(unit.symbol)", value)
    }
    
    private func formatDelta(_ kg: Double) -> String {
        guard let unit = dataManager.settings?.preferredUnit else {
            return String(format: "%.1f kg", kg)
        }
        
        let value = unit.convert(fromKg: kg)
        let precision = dataManager.settings?.decimalPrecision ?? 1
        return String(format: "%.\(precision)f \(unit.symbol)", value)
    }
    
    // MARK: - Plateau Card
    
    private func plateauCard(_ plateau: PlateauDetectionService.PlateauDetection) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("Plateau Detected")
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

// MARK: - Celebration Overlay View

struct CelebrationOverlayView: View {
    let celebration: CelebrationService.Celebration
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: celebration.iconName)
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce)
            
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

// MARK: - Celebration View

struct CelebrationView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce)
            
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
