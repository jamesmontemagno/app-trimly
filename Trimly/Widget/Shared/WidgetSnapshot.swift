import Foundation

/// A derived display cache, never a source of truth or a CloudKit model.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    static let currentVersion = 1
    let version: Int
    let generatedAt: Date
    let latestWeight: Double?
    let latestEntryAt: Date?
    let unitSymbol: String
    let decimalPrecision: Int
    let dailyWeights: [DailyWeight]
    let trend: Trend?
    let hidesWeights: Bool

    struct DailyWeight: Codable, Equatable, Sendable {
        let date: Date
        let value: Double
    }

    enum Trend: String, Codable, Sendable {
        case downward, upward, stable
    }

    static func empty(at date: Date = Date(), hidesWeights: Bool = false) -> WidgetSnapshot {
        WidgetSnapshot(
            version: currentVersion, generatedAt: date,
            latestWeight: nil, latestEntryAt: nil, unitSymbol: "",
            decimalPrecision: 1, dailyWeights: [], trend: nil,
            hidesWeights: hidesWeights
        )
    }

    var staleAt: Date {
        min(generatedAt.addingTimeInterval(24 * 60 * 60),
            (latestEntryAt ?? generatedAt).addingTimeInterval(48 * 60 * 60))
    }

    func isStale(at date: Date) -> Bool {
        latestWeight != nil && date >= staleAt
    }

    var dailyDelta: Double? {
        guard dailyWeights.count >= 2 else { return nil }
        return dailyWeights[dailyWeights.count - 1].value - dailyWeights[dailyWeights.count - 2].value
    }

    var isValid: Bool {
        version == Self.currentVersion
            && (1...2).contains(decimalPrecision)
            && dailyWeights.count <= 14
            && dailyWeights.allSatisfy { $0.value.isFinite && $0.value > 0 }
            && (latestWeight.map { $0.isFinite && $0 > 0 } ?? true)
            && (latestWeight == nil || (latestEntryAt != nil && ["kg", "lb", "st"].contains(unitSymbol)))
            && (!hidesWeights || (latestWeight == nil && latestEntryAt == nil && dailyWeights.isEmpty && trend == nil))
    }
}

nonisolated enum WidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.refractored.trimtally"
    static let widgetKind = "TrimlyWidget"
    static let fileName = "weight-widget-snapshot.json"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    static func load(from directory: URL?) -> WidgetSnapshot? {
        guard let directory,
              let data = try? Data(contentsOf: directory.appendingPathComponent(fileName)),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              snapshot.isValid else { return nil }
        return snapshot
    }

    static func write(_ snapshot: WidgetSnapshot, to directory: URL) throws {
        let url = directory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(snapshot)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
        var resourceURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? resourceURL.setResourceValues(values)
    }
}
