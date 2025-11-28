//
//  DataManager.swift
//  Trimly
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
    }
    
    func updateEntry(_ entry: WeightEntry, notes: String?) throws {
        entry.notes = notes
        entry.updatedAt = Date()
        try modelContext.save()
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
        // Delete all entries
        let entryDescriptor = FetchDescriptor<WeightEntry>()
        let entries = try modelContext.fetch(entryDescriptor)
        for entry in entries {
            modelContext.delete(entry)
        }
        
        // Delete all goals
        let goalDescriptor = FetchDescriptor<Goal>()
        let goals = try modelContext.fetch(goalDescriptor)
        for goal in goals {
            modelContext.delete(goal)
        }
        
        // Reset onboarding-related settings so the setup wizard runs again
        if let settings = settings {
            settings.hasCompletedOnboarding = false
            settings.eulaAcceptedDate = nil
            settings.consecutiveReminderDismissals = 0
            settings.updatedAt = Date()
        }
        
        try modelContext.save()
    }
}
