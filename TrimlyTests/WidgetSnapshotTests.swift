import Foundation
import Testing
@testable import TrimTally

@MainActor
struct WidgetSnapshotTests {
    private var now: Date { Date() }

    @Test
    func latestVisibleMeasurementUsesPreferredUnitAndPrecision() throws {
        let manager = DataManager(inMemory: true)
        let date = now
        try manager.addWeightEntry(weightKg: 80, timestamp: date.addingTimeInterval(-120), unit: .kilograms)
        try manager.addWeightEntry(weightKg: 90, timestamp: date.addingTimeInterval(-60), unit: .kilograms)
        let hidden = try #require(manager.fetchAllEntries().first)
        try manager.setEntryHidden(hidden, isHidden: true)
        manager.updateSettings {
            $0.preferredUnit = .stones
            $0.decimalPrecision = 2
        }
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager, at: date)
        #expect(snapshot.latestWeight == WeightUnit.stones.convert(fromKg: 80))
        #expect(snapshot.latestEntryAt == date.addingTimeInterval(-120))
        #expect(snapshot.unitSymbol == "st")
        #expect(snapshot.decimalPrecision == 2)
        #expect(snapshot.isValid)
    }

    @Test
    func dailyTrendAggregatesMultipleEntriesInsteadOfUsingRawMeasurements() throws {
        let manager = DataManager(inMemory: true)
        let today = Calendar.current.startOfDay(for: now)
        let day = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))
        try manager.addWeightEntry(weightKg: 80, timestamp: day.addingTimeInterval(3600), unit: .kilograms)
        try manager.addWeightEntry(weightKg: 82, timestamp: day.addingTimeInterval(7200), unit: .kilograms)
        manager.updateSettings {
            $0.preferredUnit = .kilograms
            $0.dailyAggregationMode = .average
        }
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager)
        #expect(snapshot.latestWeight == 82)
        #expect(snapshot.dailyWeights.count == 1)
        #expect(snapshot.dailyWeights.first?.value == 81)
        #expect(snapshot.trend == nil)
        #expect(snapshot.dailyDelta == nil)
        manager.updateSettings { $0.dailyAggregationMode = .latest }
        #expect(WidgetSnapshotWriter.makeSnapshot(using: manager).dailyWeights.first?.value == 82)
    }

    @Test
    func dailyHistoryIsBoundedAndTrendUsesKgRegardlessOfDisplayUnit() throws {
        let manager = DataManager(inMemory: true)
        let date = now
        let calendar = Calendar.current
        for offset in 1...20 {
            let day = try #require(calendar.date(byAdding: .day, value: -offset, to: date))
            try manager.addWeightEntry(weightKg: 80 + Double(offset), timestamp: day, unit: .kilograms)
        }
        manager.updateSettings { $0.preferredUnit = .pounds }
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager, at: date)
        #expect(snapshot.dailyWeights.count <= 14)
        #expect(snapshot.trend == .downward)
        let delta = try #require(snapshot.dailyDelta)
        #expect(abs(delta - WeightUnit.pounds.convert(fromKg: -1)) < 0.0001)
    }

    @Test
    func fewerThanSevenDaysDoesNotClaimAStableTrend() throws {
        let manager = DataManager(inMemory: true)
        for offset in 1...3 {
            let day = try #require(Calendar.current.date(byAdding: .day, value: -offset, to: now))
            try manager.addWeightEntry(weightKg: 80 + Double(offset), timestamp: day, unit: .kilograms)
        }
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager)
        #expect(snapshot.dailyWeights.count == 3)
        #expect(snapshot.trend == nil)
    }

    @Test
    func deletionAndHidingClearCachedMeasurements() throws {
        let manager = DataManager(inMemory: true)
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms)
        let entry = try #require(manager.fetchAllEntries().first)
        try manager.setEntryHidden(entry, isHidden: true)
        #expect(WidgetSnapshotWriter.makeSnapshot(using: manager).latestWeight == nil)
        try manager.setEntryHidden(entry, isHidden: false)
        #expect(WidgetSnapshotWriter.makeSnapshot(using: manager).latestWeight != nil)
        try manager.deleteEntry(entry)
        let cleared = WidgetSnapshotWriter.makeSnapshot(using: manager)
        #expect(cleared.latestWeight == nil)
        #expect(cleared.latestEntryAt == nil)
        #expect(cleared.dailyWeights.isEmpty)
        #expect(cleared.trend == nil)
    }

    @Test
    func editingMeasurementUpdatesDerivedWeightAndDate() throws {
        let manager = DataManager(inMemory: true)
        let date = now.addingTimeInterval(-3600)
        try manager.addWeightEntry(weightKg: 80, timestamp: date, unit: .kilograms)
        let entry = try #require(manager.fetchAllEntries().first)
        let revisedDate = date.addingTimeInterval(-60)
        try manager.updateEntry(entry, weightKg: 79, timestamp: revisedDate, unit: .kilograms, notes: nil)
        manager.updateSettings { $0.preferredUnit = .kilograms }
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager)
        #expect(snapshot.latestWeight == 79)
        #expect(snapshot.latestEntryAt == revisedDate)
    }

    @Test
    func devicePrivacyRemovesMeasurementsFromSerializedCache() throws {
        let manager = DataManager(inMemory: true)
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms)
        manager.deviceSettings.updatePresentation { $0.hideWeights = true }
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager)
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        #expect(decoded.hidesWeights)
        #expect(decoded.latestWeight == nil)
        #expect(decoded.latestEntryAt == nil)
        #expect(decoded.dailyWeights.isEmpty)
        #expect(decoded.trend == nil)
        #expect(decoded.isValid)
    }

    @Test
    func snapshotRoundTripsWithoutAppModelReferences() throws {
        let manager = DataManager(inMemory: true)
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms)
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager)
        let encoded = try JSONEncoder().encode(snapshot)
        #expect(try JSONDecoder().decode(WidgetSnapshot.self, from: encoded) == snapshot)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(json["notes"] == nil)
        #expect(json["source"] == nil)
        #expect(json["id"] == nil)
    }

    @Test
    func staleStateReflectsBothCacheAgeAndMeasurementAge() throws {
        let manager = DataManager(inMemory: true)
        let date = now
        try manager.addWeightEntry(weightKg: 80, timestamp: date, unit: .kilograms)
        let snapshot = WidgetSnapshotWriter.makeSnapshot(using: manager, at: date)
        #expect(!snapshot.isStale(at: date))
        #expect(snapshot.isStale(at: date.addingTimeInterval(24 * 60 * 60)))
        let later = WidgetSnapshotWriter.makeSnapshot(using: manager, at: date.addingTimeInterval(49 * 60 * 60))
        #expect(later.isStale(at: later.generatedAt))
        #expect(!WidgetSnapshot.empty(at: date).isStale(at: date.addingTimeInterval(100_000)))
    }

    @Test
    func unsupportedCacheVersionIsRejected() throws {
        let data = try JSONEncoder().encode(WidgetSnapshot.empty())
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["version"] = 999
        let modified = try JSONSerialization.data(withJSONObject: json)
        #expect(!(try JSONDecoder().decode(WidgetSnapshot.self, from: modified)).isValid)
        #expect(WidgetSnapshotStore.load(from: nil) == nil)
    }

    @Test
    func inMemoryRefreshDoesNotAccessSharedContainer() throws {
        let manager = DataManager(inMemory: true)
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms)
        var requestedContainer = false
        WidgetSnapshotWriter.refresh(using: manager, resolveContainer: {
            requestedContainer = true
            return nil
        })
        #expect(!requestedContainer)
    }
}
