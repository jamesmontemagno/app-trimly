//
//  DataManager.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import SwiftData
import Combine

/// Central data management service
@MainActor
final class DataManager: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    @Published var settings: AppSettings?

    /// Ensures SwiftUI views refresh when persisted data changes
    private func publishChange() {
        objectWillChange.send()
    }
    
    init(inMemory: Bool = false) {
        let schema = Schema([
            WeightEntry.self,
            Goal.self,
            AppSettings.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            modelContext = ModelContext(modelContainer)
            
            // Load or create settings
            loadSettings()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let existingSettings = try modelContext.fetch(descriptor)
            if let first = existingSettings.first {
                settings = first
            } else {
                // Create default settings
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                try modelContext.save()
                settings = newSettings
            }
        } catch {
            print("Failed to load settings: \(error)")
            // Create default settings anyway
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            settings = newSettings
            try? modelContext.save()
        }
    }
    
    func updateSettings(_ update: (inout AppSettings) -> Void) {
        guard var settings = settings else { return }
        update(&settings)
        settings.updatedAt = Date()
        try? modelContext.save()
        publishChange()
    }
    
    // MARK: - Weight Entry Management
    
    func addWeightEntry(
        weightKg: Double,
        timestamp: Date = Date(),
        unit: WeightUnit,
        notes: String? = nil,
        source: EntrySource = .manual
    ) throws {
        let entry = WeightEntry(
            timestamp: timestamp,
            weightKg: weightKg,
            displayUnitAtEntry: unit,
            source: source,
            notes: notes
        )
        modelContext.insert(entry)
        try modelContext.save()
        publishChange()
    }
    
    func fetchAllEntries() -> [WeightEntry] {
        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchEntriesForDate(_ date: Date) -> [WeightEntry] {
        let normalizedDate = WeightEntry.normalizeDate(date)
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { $0.normalizedDate == normalizedDate },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteEntry(_ entry: WeightEntry) throws {
        modelContext.delete(entry)
        try modelContext.save()
        publishChange()
    }
    
    func updateEntry(_ entry: WeightEntry, notes: String?) throws {
        entry.notes = notes
        entry.updatedAt = Date()
        try modelContext.save()
        publishChange()
    }
    
    // MARK: - Goal Management
    
    func setGoal(targetWeightKg: Double, startingWeightKg: Double?, targetDate: Date? = nil, notes: String? = nil) throws {
        // Archive current active goal if exists
        if let activeGoal = fetchActiveGoal() {
            activeGoal.archive(reason: .changed)
        }
        
        let goal = Goal(
            targetWeightKg: targetWeightKg,
            targetDate: targetDate,
            startingWeightKg: startingWeightKg,
            notes: notes
        )
        modelContext.insert(goal)
        try modelContext.save()
        publishChange()
    }
    
    func fetchActiveGoal() -> Goal? {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func fetchGoalHistory() -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isActive == false },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func completeGoal(reason: CompletionReason) throws {
        guard let activeGoal = fetchActiveGoal() else { return }
        activeGoal.archive(reason: reason)
        try modelContext.save()
        publishChange()
    }
    
    // MARK: - Analytics
    
    func getDailyWeights(mode: DailyAggregationMode? = nil) -> [(date: Date, weight: Double)] {
        let entries = fetchAllEntries()
        let aggregationMode = mode ?? settings?.dailyAggregationMode ?? .latest
        let dailyDict = WeightAnalytics.aggregateByDay(entries: entries, mode: aggregationMode)
        return dailyDict.map { (date: $0.key, weight: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    func getCurrentWeight() -> Double? {
        let entries = fetchAllEntries()
        return entries.first?.weightKg
    }
    
    func getStartWeight() -> Double? {
        let entries = fetchAllEntries()
        return entries.last?.weightKg
    }
    
    func getConsistencyScore() -> Double? {
        guard let settings = settings else { return nil }
        let entries = fetchAllEntries()
        return WeightAnalytics.calculateConsistencyScore(
            entries: entries,
            windowDays: settings.consistencyScoreWindow
        )
    }
    
    func getTrend() -> WeightAnalytics.TrendDirection {
        let dailyWeights = getDailyWeights()
        return WeightAnalytics.classifyTrend(dailyWeights: dailyWeights)
    }
    
    func getGoalProjection() -> Date? {
        guard let goal = fetchActiveGoal(),
              let settings = settings else { return nil }
        
        let dailyWeights = getDailyWeights()
        return WeightAnalytics.calculateGoalProjection(
            dailyWeights: dailyWeights,
            targetWeightKg: goal.targetWeightKg,
            minDays: settings.minDaysForProjection
        )
    }
    
    // MARK: - Data Export
    
    func exportToCSV() -> String {
        let entries = fetchAllEntries()
        var csv = "id,timestamp,normalizedDate,weight_kg,displayUnitAtEntry,weight_display_value,source,notes,createdAt,updatedAt\n"
        
        let dateFormatter = ISO8601DateFormatter()
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        
        for entry in entries.reversed() { // Oldest first
            let id = entry.id.uuidString
            let timestamp = dateFormatter.string(from: entry.timestamp)
            let normalizedDate = dateOnlyFormatter.string(from: entry.normalizedDate)
            let weightKg = String(format: "%.2f", entry.weightKg)
            let unit = entry.displayUnitAtEntry.rawValue
            let displayValue = String(format: "%.1f", entry.displayValue)
            let source = entry.source.rawValue
            let notes = entry.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            let createdAt = dateFormatter.string(from: entry.createdAt)
            let updatedAt = dateFormatter.string(from: entry.updatedAt)
            
            csv += "\(id),\(timestamp),\(normalizedDate),\(weightKg),\(unit),\(displayValue),\(source),\"\(notes)\",\(createdAt),\(updatedAt)\n"
        }
        
        return csv
    }
    
    // MARK: - Data Deletion
    
    func deleteAllData() throws {
        // Delete all entries and goals using batch delete
        try modelContext.delete(model: WeightEntry.self)
        try modelContext.delete(model: Goal.self)
        
        // Reset onboarding-related settings so the setup wizard runs again
        if let settings = settings {
            settings.hasCompletedOnboarding = false
            settings.eulaAcceptedDate = nil
            settings.consecutiveReminderDismissals = 0
            settings.updatedAt = Date()
        }
        
        try modelContext.save()
        publishChange()
    }

#if DEBUG
    // MARK: - Debug Helpers
    /// Removes existing entries and creates a 30-day downward trend (165 lb → 160 lb) for visualization in debug builds.
    func generateSampleData(days: Int = 30) throws {
        try modelContext.delete(model: WeightEntry.self)
        try modelContext.save()
		
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        let preferredUnit = settings?.preferredUnit ?? .kilograms
        let poundsUnit: WeightUnit = .pounds
        let startWeightKg = poundsUnit.convertToKg(165)
        let goalWeightKg = poundsUnit.convertToKg(160)
        let minClamp = goalWeightKg - poundsUnit.convertToKg(0.5)
        let maxClamp = startWeightKg + poundsUnit.convertToKg(0.5)
        let totalDays = max(days, 2)
        let notePool = [
            "Post-run weigh-in",
            "High sodium dinner",
            "Travel day water retention",
            "Slept great",
            "Lift day recovery"
        ]
		
        for dayOffset in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: baseDate) else { continue }
            let entriesForDay = Int.random(in: 1...2)
            for entryIndex in 0..<entriesForDay {
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = 6 + entryIndex * 3 + Int.random(in: 0...2)
                components.minute = Int.random(in: 0...55)
                components.second = Int.random(in: 0...50)
                let timestamp = calendar.date(from: components) ?? day
				
				let progress = Double(totalDays - 1 - dayOffset) / Double(totalDays - 1)
				let trendKg = startWeightKg - progress * (startWeightKg - goalWeightKg)
				let rippleKg = poundsUnit.convertToKg(sin(Double(dayOffset) / 5.5) * 0.3)
				let randomKg = poundsUnit.convertToKg(Double.random(in: -0.6...0.6))
				let weightKg = min(max(trendKg + rippleKg + randomKg, minClamp), maxClamp)
                let note = Bool.random() ? notePool.randomElement() : nil
                let entry = WeightEntry(
                    timestamp: timestamp,
                    weightKg: weightKg,
                    displayUnitAtEntry: preferredUnit,
                    notes: note
                )
                modelContext.insert(entry)
            }
        }
        try modelContext.save()
        publishChange()
    }
#endif
}
