//
//  HealthKitService.swift
//  Weigh
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import Combine
import HealthKit

/// Service for HealthKit integration (weight data import and sync)
@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    private let syncOverlapSeconds: TimeInterval = 600 // re-read a small window to avoid missing edge samples
    private var observerQuery: HKObserverQuery?
    private var importWaiters: [CheckedContinuation<Void, Never>] = []
    
    @Published var isAuthorized = false
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published private(set) var skippedSampleCount = 0
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    static func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization to read and write weight data
    func requestAuthorization() async throws {
        let typesToRead: Set<HKSampleType> = [weightType]
        let typesToShare: Set<HKSampleType> = [weightType]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        
        let status = healthStore.authorizationStatus(for: weightType)
        isAuthorized = (status == .sharingAuthorized)
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: weightType)
        isAuthorized = (status == .sharingAuthorized)
    }

    /// Save a single weight entry to HealthKit
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - timestamp: Date of the measurement
    func saveWeightToHealthKit(weightKg: Double, timestamp: Date) async throws {
        guard HealthKitService.isHealthKitAvailable() else {
            throw HealthKitError.notAvailable
        }
        let status = healthStore.authorizationStatus(for: weightType)
        guard status == .sharingAuthorized else {
            throw HealthKitError.notAuthorized
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: timestamp, end: timestamp)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.importFailed(error))
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.importFailed(NSError(domain: "HealthKit", code: -1)))
                }
            }
        }
    }
    
    // MARK: - Historical Import
    
    /// Import historical weight data from HealthKit
    /// - Parameters:
    ///   - startDate: Start date for import
    ///   - endDate: End date for import
    ///   - dataManager: Data manager to save entries
    ///   - unit: Preferred weight unit
    /// - Returns: Number of samples imported
    @discardableResult
    func importHistoricalData(
        from startDate: Date,
        to endDate: Date,
        dataManager: DataManager,
        unit: WeightUnit
    ) async throws -> Int {
        await waitForImport()
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        isImporting = true
        importProgress = 0
        skippedSampleCount = 0
        
        defer {
            isImporting = false
            importProgress = 0
            let waiting = importWaiters
            importWaiters.removeAll()
            waiting.forEach { $0.resume() }
        }
        
        // Query for weight samples
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let samples = results as? [HKQuantitySample] ?? []
                continuation.resume(returning: samples)
            }
            
            healthStore.execute(query)
        }
        
        // Process samples and check for duplicates
        let totalSamples = samples.count
        let healthSettings = dataManager.deviceSettings.healthKit
        var duplicateCandidates: [Int: [(timestamp: Date, weightKg: Double)]] = [:]
        if healthSettings.autoHideDuplicates {
            let existingEntries = try dataManager.fetchEntries(
                startDate: startDate.addingTimeInterval(-300),
                endDate: endDate.addingTimeInterval(301),
                includeHidden: true
            )
            for entry in existingEntries {
                addDuplicateCandidate(
                    timestamp: entry.timestamp,
                    weightKg: entry.weightKg,
                    to: &duplicateCandidates
                )
            }
        }
        var drafts: [WeightEntryDraft] = []
        
        for (index, sample) in samples.enumerated() {
            // Update progress
            importProgress = Double(index) / Double(totalSamples)
            
            let weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            let timestamp = sample.startDate
            
            let isDuplicate = healthSettings.autoHideDuplicates && containsDuplicate(
                weightKg: weightKg,
                timestamp: timestamp,
                tolerance: healthSettings.duplicateToleranceKg,
                candidates: duplicateCandidates
            )
            if isDuplicate {
                skippedSampleCount += 1
            } else {
                drafts.append(WeightEntryDraft(
                    weightKg: weightKg,
                    timestamp: timestamp,
                    unit: unit,
                    notes: nil
                ))
                addDuplicateCandidate(
                    timestamp: timestamp,
                    weightKg: weightKg,
                    to: &duplicateCandidates
                )
            }
        }
        
        let importedCount = try dataManager.importHealthKitEntries(drafts)
        importProgress = 1.0
        return importedCount
    }
    
    /// Get sample count for a date range (for preview)
    func getSampleCount(from startDate: Date, to endDate: Date) async throws -> Int {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let count = results?.count ?? 0
                continuation.resume(returning: count)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Background Sync
    
    /// Enable background delivery for weight updates
    func enableBackgroundDelivery(dataManager: DataManager, unit: WeightUnit) {
        guard isAuthorized else { return }
        
        healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate) { [weak self] success, error in
            if success {
                Task { @MainActor in
                    await self?.observeWeightChanges(dataManager: dataManager, unit: unit)
                }
            }
        }
    }

    func disableBackgroundDelivery() {
        if let observerQuery {
            healthStore.stop(observerQuery)
            self.observerQuery = nil
        }
        healthStore.disableBackgroundDelivery(for: weightType) { _, _ in }
    }
    
    /// Register background delivery on app launch if enabled in settings
    /// Call this from the app entry point to ensure background sync is active after app restarts
    func registerBackgroundDeliveryIfEnabled(dataManager: DataManager) {
        guard HealthKitService.isHealthKitAvailable() else { return }
        guard dataManager.deviceSettings.healthKit.backgroundSyncEnabled else { return }
        
        // Check authorization status first
        checkAuthorizationStatus()
        guard isAuthorized else { return }
        
        // Get preferred unit from settings, default to kilograms
        let unit = dataManager.settings?.preferredUnit ?? .kilograms
        enableBackgroundDelivery(dataManager: dataManager, unit: unit)

        // Perform a catch-up sync on launch so we ingest any samples added while the app was not running
        Task { @MainActor [weak self] in
            await self?.syncRecentSamples(dataManager: dataManager, unit: unit)
        }
    }
    
    /// Observe weight changes and sync new samples
    @MainActor
    private func observeWeightChanges(dataManager: DataManager, unit: WeightUnit) async {
        guard observerQuery == nil, dataManager.deviceSettings.healthKit.backgroundSyncEnabled else { return }
        let query = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] _, completionHandler, error in
            let completion = HealthObserverCompletion(completionHandler)
            guard error == nil else {
                completion.finish()
                return
            }
            
            Task { @MainActor [weak self] in
                await self?.syncRecentSamples(dataManager: dataManager, unit: unit)
                completion.finish()
            }
        }
        observerQuery = query
        healthStore.execute(query)
    }
    
    /// Sync recent weight samples from the last known sync point (with a small overlap) through now
    private func syncRecentSamples(dataManager: DataManager, unit: WeightUnit) async {
        await waitForImport()
        guard isAuthorized, dataManager.deviceSettings.healthKit.backgroundSyncEnabled else { return }
        let now = Date()
        let startDate = syncStartDate(deviceSettings: dataManager.deviceSettings, now: now)
        do {
            try await importHistoricalData(
                from: startDate,
                to: now,
                dataManager: dataManager,
                unit: dataManager.settings?.preferredUnit ?? unit
            )
            await dataManager.waitForPendingWidgetRefresh()
            dataManager.deviceSettings.updateHealthKit { settings in
                settings.lastBackgroundSyncAt = now
            }
        } catch {
            dataManager.persistenceErrorMessage = error.localizedDescription
        }
    }

    private func waitForImport() async {
        while isImporting {
            await withCheckedContinuation { continuation in
                importWaiters.append(continuation)
            }
        }
    }
    
    // MARK: - Duplicate Detection
    
    /// Check if a HealthKit sample is a duplicate
    func isDuplicate(
        weightKg: Double,
        timestamp: Date,
        dataManager: DataManager
    ) throws -> Bool {
        let healthSettings = dataManager.deviceSettings.healthKit
        guard healthSettings.autoHideDuplicates else { return false }
        let tolerance = healthSettings.duplicateToleranceKg
        // Include adjacent days: samples near midnight can match across a day boundary.
        let existingEntries = try dataManager.fetchEntries(
            startDate: timestamp.addingTimeInterval(-300),
            endDate: timestamp.addingTimeInterval(301),
            includeHidden: true
        )
        
        // Check if there's a matching entry within tolerance
        for entry in existingEntries {
            let weightDifference = abs(entry.weightKg - weightKg)
            let timeDifference = abs(entry.timestamp.timeIntervalSince(timestamp))
            
            // Match if weights are within tolerance and within 5 minutes
            if weightDifference <= tolerance && timeDifference <= 300 {
                return true
            }
        }
        
        return false
    }

    private func containsDuplicate(
        weightKg: Double,
        timestamp: Date,
        tolerance: Double,
        candidates: [Int: [(timestamp: Date, weightKg: Double)]]
    ) -> Bool {
        let bucket = duplicateBucket(for: timestamp)
        for candidateBucket in (bucket - 1)...(bucket + 1) {
            guard let entries = candidates[candidateBucket] else { continue }
            if entries.contains(where: {
                abs($0.weightKg - weightKg) <= tolerance
                    && abs($0.timestamp.timeIntervalSince(timestamp)) <= 300
            }) {
                return true
            }
        }
        return false
    }

    private func addDuplicateCandidate(
        timestamp: Date,
        weightKg: Double,
        to candidates: inout [Int: [(timestamp: Date, weightKg: Double)]]
    ) {
        candidates[duplicateBucket(for: timestamp), default: []].append((timestamp, weightKg))
    }

    private func duplicateBucket(for timestamp: Date) -> Int {
        Int(floor(timestamp.timeIntervalSinceReferenceDate / 300))
    }

    /// Determine the start date for the next sync using the most recent sync/import anchor and a small overlap window
    private func syncStartDate(deviceSettings: DeviceSettingsStore, now: Date = Date()) -> Date {
        let anchor = deviceSettings.healthKit.lastBackgroundSyncAt ?? deviceSettings.healthKit.lastImportAt
        if let anchor {
            let overlap = deviceSettings.healthKit.autoHideDuplicates ? -syncOverlapSeconds : 0
            return anchor.addingTimeInterval(overlap)
        }
        if let fallback = Calendar.current.date(byAdding: .day, value: -30, to: now) {
            return fallback
        }
        return now
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    case importFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return NSLocalizedString("platform.health.notAuthorized", tableName: "PlatformFeatures", comment: "HealthKit authorization error")
        case .notAvailable:
            return NSLocalizedString("platform.health.notAvailable", tableName: "PlatformFeatures", comment: "HealthKit availability error")
        case .importFailed(let error):
            return String(format: NSLocalizedString("platform.health.importFailed", tableName: "PlatformFeatures", comment: "HealthKit import error"), error.localizedDescription)
        }
    }
}

/// HealthKit supplies a non-Sendable completion block; the lock guarantees one invocation.
private final class HealthObserverCompletion: @unchecked Sendable {
    nonisolated private let lock = NSLock()
    nonisolated(unsafe) private var completion: (() -> Void)?

    nonisolated init(_ completion: @escaping () -> Void) {
        self.completion = completion
    }

    nonisolated func finish() {
        lock.lock()
        let callback = completion
        completion = nil
        lock.unlock()
        callback?()
    }
}
