import Foundation
import WidgetKit
import OSLog

private actor WidgetSnapshotPersistence {
    private var latestSequence = 0

    func persist(
        _ snapshot: WidgetSnapshot,
        sequence: Int,
        resolveContainer: @Sendable () -> URL?
    ) {
        guard sequence >= latestSequence else { return }
        latestSequence = sequence
        guard let directory = resolveContainer() else {
            Logger(subsystem: "com.refractored.trimtally", category: "Widget").error("The widget App Group container is unavailable.")
            return
        }
        do {
            try WidgetSnapshotStore.write(snapshot, to: directory)
        } catch {
            // Invalidate the old cache rather than leaving deleted/private weights on disk.
            let cacheURL = directory.appendingPathComponent(WidgetSnapshotStore.fileName)
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                do {
                    try FileManager.default.removeItem(at: cacheURL)
                } catch {
                    Logger(subsystem: "com.refractored.trimtally", category: "Widget").error("Unable to invalidate the widget cache.")
                }
            }
            Logger(subsystem: "com.refractored.trimtally", category: "Widget").error("Unable to refresh the widget cache.")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshotStore.widgetKind)
    }
}

/// App-only bridge from SwiftData to the extension's value-only cache.
@MainActor
enum WidgetSnapshotWriter {
    private static let persistence = WidgetSnapshotPersistence()
    private static var sequence = 0

    static func makeSnapshot(using dataManager: DataManager, at date: Date = Date()) -> WidgetSnapshot {
        let hidesWeights = dataManager.deviceSettings.presentation.hideWeights
        guard !hidesWeights else { return .empty(at: date, hidesWeights: true) }
        let visibleEntries = dataManager.fetchAllEntries().filter { !$0.isHidden && $0.timestamp <= date }
        guard let latest = visibleEntries.first else { return .empty(at: date) }
        let unit = dataManager.settings?.preferredUnit ?? .kilograms
        let start = Calendar.current.date(
            byAdding: .day, value: -13, to: Calendar.current.startOfDay(for: date)
        ) ?? date
        let daily = WeightAnalytics.aggregateByDay(
            entries: visibleEntries.filter { $0.timestamp >= start },
            mode: dataManager.settings?.dailyAggregationMode ?? .latest
        ).map { (date: $0.key, weight: $0.value) }.sorted { $0.date < $1.date }

        let trend: WidgetSnapshot.Trend?
        if daily.count < 7 {
            trend = nil
        } else {
            switch WeightAnalytics.classifyTrend(dailyWeights: daily) {
            case .downward: trend = .downward
            case .upward: trend = .upward
            case .stable: trend = .stable
            }
        }
        return WidgetSnapshot(
            version: WidgetSnapshot.currentVersion, generatedAt: date,
            latestWeight: unit.convert(fromKg: latest.weightKg), latestEntryAt: latest.timestamp,
            unitSymbol: unit.symbol, decimalPrecision: min(2, max(1, dataManager.settings?.decimalPrecision ?? 1)),
            dailyWeights: daily.map { .init(date: $0.date, value: unit.convert(fromKg: $0.weight)) },
            trend: trend, hidesWeights: false
        )
    }

    /// Cache failures must never cause an otherwise successful data mutation to fail.
    @discardableResult
    static func refresh(using dataManager: DataManager) -> Task<Void, Never>? {
        refresh(using: dataManager, resolveContainer: { WidgetSnapshotStore.containerURL })
    }

    @discardableResult
    static func refresh(
        using dataManager: DataManager,
        resolveContainer: @escaping @Sendable () -> URL?
    ) -> Task<Void, Never>? {
        guard !dataManager.isInMemory else { return nil }
        sequence += 1
        let currentSequence = sequence
        let snapshot = makeSnapshot(using: dataManager)
        return Task.detached(priority: .utility) {
            await persistence.persist(
                snapshot,
                sequence: currentSequence,
                resolveContainer: resolveContainer
            )
        }
    }
}
