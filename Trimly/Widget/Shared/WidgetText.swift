import Foundation

nonisolated enum WidgetText {
    static let title = LocalizedStringResource("platform.widget.title", defaultValue: "Latest Weight", table: "PlatformFeatures")
    static let description = LocalizedStringResource("platform.widget.description", defaultValue: "Your latest visible weight and daily trend. Tap to log a weight.", table: "PlatformFeatures")
    static let hidden = LocalizedStringResource("platform.widget.hidden", defaultValue: "Weights hidden", table: "PlatformFeatures")
    static let empty = LocalizedStringResource("platform.widget.empty", defaultValue: "Open the app to log a weight", table: "PlatformFeatures")
    static let stale = LocalizedStringResource("platform.widget.stale", defaultValue: "Older data · Open app", table: "PlatformFeatures")
    static let current = LocalizedStringResource("platform.widget.current", defaultValue: "Recent data", table: "PlatformFeatures")
    static let quickLog = LocalizedStringResource("platform.quickLog.title", defaultValue: "Log Weight", table: "PlatformFeatures")
    static let quickLogHint = LocalizedStringResource("platform.quickLog.description", defaultValue: "Open the weight entry form. Nothing is saved until you confirm.", table: "PlatformFeatures")
    static let trendTitle = LocalizedStringResource("platform.widget.trendTitle", defaultValue: "14-day trend", table: "PlatformFeatures")
    static let insufficientTrend = LocalizedStringResource("platform.widget.insufficientTrend", defaultValue: "Log on more days for a trend", table: "PlatformFeatures")
    static let downward = LocalizedStringResource("platform.widget.downward", defaultValue: "Decreasing", table: "PlatformFeatures")
    static let upward = LocalizedStringResource("platform.widget.upward", defaultValue: "Increasing", table: "PlatformFeatures")
    static let stable = LocalizedStringResource("platform.widget.stable", defaultValue: "Stable", table: "PlatformFeatures")

    static func weight(_ value: String, _ unit: String) -> LocalizedStringResource {
        LocalizedStringResource("platform.widget.weight", defaultValue: "\(value) \(unit)", table: "PlatformFeatures")
    }

    static func inlineWeight(_ weight: String, _ freshness: String) -> LocalizedStringResource {
        LocalizedStringResource("platform.widget.inlineWeight", defaultValue: "\(weight) \(freshness)", table: "PlatformFeatures")
    }

    static func delta(_ value: String) -> LocalizedStringResource {
        LocalizedStringResource("platform.widget.delta", defaultValue: "Since previous logged day: \(value)", table: "PlatformFeatures")
    }

    static func accessibility(_ weight: String, _ date: String, _ trend: String, _ freshness: String) -> LocalizedStringResource {
        LocalizedStringResource("platform.widget.accessibility", defaultValue: "Latest weight: \(weight). Logged \(date). \(trend). \(freshness).", table: "PlatformFeatures")
    }
}
