import SwiftUI
import WidgetKit
import Charts

@main
struct MyWeightWidgetBundle: WidgetBundle {
    var body: some Widget { MyWeightWidget() }
}

struct MyWeightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshotStore.widgetKind, provider: WeightProvider()) { entry in
            WeightWidgetEntryView(entry: entry)
                .widgetURL(QuickLogLink.url)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName(String(localized: WidgetText.title))
        .description(String(localized: WidgetText.description))
        .supportedFamilies(families)
    }

    private var families: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }
}

struct WidgetTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct WeightProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetTimelineEntry {
        WidgetTimelineEntry(date: Date(), snapshot: .empty())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetTimelineEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetTimelineEntry>) -> Void) {
        let entry = currentEntry()
        var entries = [entry]
        if entry.snapshot.latestWeight != nil && entry.snapshot.staleAt > entry.date {
            entries.append(WidgetTimelineEntry(date: entry.snapshot.staleAt, snapshot: entry.snapshot))
        }
        // WidgetKit controls refresh budgets; the cached entry also expires without an app launch.
        completion(Timeline(entries: entries, policy: .after(entry.date.addingTimeInterval(60 * 60))))
    }

    private func currentEntry() -> WidgetTimelineEntry {
        let date = Date()
        return WidgetTimelineEntry(date: date, snapshot: WidgetSnapshotStore.load(from: WidgetSnapshotStore.containerURL) ?? .empty(at: date))
    }
}

struct WeightWidgetEntryView: View {
    let entry: WidgetTimelineEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.redactionReasons) private var redactionReasons

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var isPrivate: Bool { snapshot.hidesWeights || redactionReasons.contains(.privacy) }
    private var hasWeight: Bool { !isPrivate && snapshot.latestWeight != nil }
    private var isStale: Bool { snapshot.isStale(at: entry.date) }
    private var status: LocalizedStringResource {
        isPrivate ? WidgetText.hidden : WidgetText.empty
    }

    var body: some View {
        Group {
            switch family {
            #if os(iOS)
            case .accessoryInline:
                if hasWeight {
                    Text(WidgetText.inlineWeight(weightText, isStale ? String(localized: WidgetText.stale) : ""))
                } else {
                    Label(String(localized: status), systemImage: isPrivate ? "lock.fill" : "plus.circle")
                }
            case .accessoryCircular:
                VStack(spacing: 2) {
                    Image(systemName: isStale ? "clock.badge.exclamationmark" : "plus.circle")
                        .accessibilityHidden(true)
                    if hasWeight {
                        Text(weightNumber).font(.headline).minimumScaleFactor(0.7)
                        Text(snapshot.unitSymbol).font(.caption2)
                    } else {
                        Text(status).font(.caption2).multilineTextAlignment(.center)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text(WidgetText.title).font(.headline)
                    if hasWeight {
                        Text(weightText).font(.headline)
                        Text(isStale ? WidgetText.stale : WidgetText.quickLog).font(.caption)
                    } else {
                        Text(status).font(.caption)
                    }
                }
            #endif
            default:
                standardLayout
            }
        }
        .privacySensitive()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(String(localized: WidgetText.quickLogHint))
    }

    private var standardLayout: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label(String(localized: WidgetText.title), systemImage: "scalemass")
                    .font(.caption)
                if hasWeight {
                    Text(weightText)
                        .font(.title2.bold())
                        .minimumScaleFactor(0.6)
                    if let date = snapshot.latestEntryAt {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                    if isStale {
                        Label(String(localized: WidgetText.stale), systemImage: "clock.badge.exclamationmark")
                            .font(.caption2)
                    }
                } else {
                    Text(status).font(.headline)
                }
                Spacer(minLength: 0)
                Label(String(localized: WidgetText.quickLog), systemImage: "plus.circle")
                    .font(.caption)
            }
            if family == .systemMedium && hasWeight {
                VStack(alignment: .leading, spacing: 6) {
                    Text(WidgetText.trendTitle).font(.caption)
                    if snapshot.dailyWeights.count >= 2 {
                        Chart(snapshot.dailyWeights, id: \.date) { point in
                            LineMark(x: .value("date", point.date), y: .value("weight", point.value))
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartYScale(domain: .automatic(includesZero: false))
                        .accessibilityHidden(true)
                        Label(trendText, systemImage: trendIcon).font(.caption2)
                        if let deltaText {
                            Text(deltaText).font(.caption2)
                        }
                    } else {
                        Text(WidgetText.insufficientTrend).font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var weightNumber: String {
        guard let weight = snapshot.latestWeight else { return "" }
        return weight.formatted(.number.precision(.fractionLength(snapshot.decimalPrecision)))
    }

    private var weightText: String {
        String(localized: WidgetText.weight(weightNumber, snapshot.unitSymbol))
    }

    private var trendText: String {
        switch snapshot.trend {
        case .downward: String(localized: WidgetText.downward)
        case .upward: String(localized: WidgetText.upward)
        case .stable: String(localized: WidgetText.stable)
        case nil: String(localized: WidgetText.insufficientTrend)
        }
    }

    private var trendIcon: String {
        switch snapshot.trend {
        case .downward: "arrow.down.right"
        case .upward: "arrow.up.right"
        case .stable: "arrow.right"
        case nil: "minus"
        }
    }

    private var accessibilitySummary: String {
        guard hasWeight, let date = snapshot.latestEntryAt else { return String(localized: status) }
        let summary = String(localized: WidgetText.accessibility(
            weightText,
            date.formatted(date: .abbreviated, time: .shortened),
            trendText,
            isStale ? String(localized: WidgetText.stale) : String(localized: WidgetText.current)
        ))
        return deltaText.map { summary + " " + $0 } ?? summary
    }

    private var deltaText: String? {
        guard let delta = snapshot.dailyDelta else { return nil }
        let number = delta.formatted(.number.precision(.fractionLength(snapshot.decimalPrecision)).sign(strategy: .always()))
        return String(localized: WidgetText.delta("\(number) \(snapshot.unitSymbol)"))
    }
}
