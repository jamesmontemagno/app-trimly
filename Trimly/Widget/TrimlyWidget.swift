//
//  TrimlyWidget.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
import WidgetKit

struct TrimlyWidget: Widget {
	let kind: String = "TrimlyWidget"
    
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: WeightProvider()) { entry in
			WeightWidgetEntryView(entry: entry)
		}
		.configurationDisplayName("Weight Tracker")
		.description("See your current weight at a glance")
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

struct WeightProvider: TimelineProvider {
	func placeholder(in context: Context) -> WidgetTimelineEntry {
		WidgetTimelineEntry(
			date: Date(),
			weight: 180.0,
			unit: .pounds,
			delta: -2.5,
			trend: .downward
		)
	}
    
	func getSnapshot(in context: Context, completion: @escaping (WidgetTimelineEntry) -> Void) {
		let entry = WidgetTimelineEntry(
			date: Date(),
			weight: 180.0,
			unit: .pounds,
			delta: -2.5,
			trend: .downward
		)
		completion(entry)
	}
    
	func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetTimelineEntry>) -> Void) {
		let currentDate = Date()
		let entry = WidgetTimelineEntry(
			date: currentDate,
			weight: 180.0,
			unit: .pounds,
			delta: -2.5,
			trend: .downward
		)
		let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
		let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
		completion(timeline)
	}
}

struct WidgetTimelineEntry: TimelineEntry {
	let date: Date
	let weight: Double
	let unit: WeightUnit
	let delta: Double
	let trend: WeightAnalytics.TrendDirection
}

struct WeightWidgetEntryView: View {
	var entry: WeightProvider.Entry
	@Environment(\.widgetFamily) var family
    
	var body: some View {
		switch family {
		case .systemSmall:
			SmallWidgetView(entry: entry)
		case .systemMedium:
			MediumWidgetView(entry: entry)
		default:
			SmallWidgetView(entry: entry)
		}
	}
}

struct SmallWidgetView: View {
	let entry: WidgetTimelineEntry
    
	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Image(systemName: "figure.mixed.cardio")
					.font(.caption)
					.foregroundStyle(.secondary)
				Spacer()
				Text(entry.unit.symbol)
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
			Spacer()
			Text(String(format: "%.1f", entry.weight))
				.font(.system(size: 36, weight: .bold, design: .rounded))
				.minimumScaleFactor(0.5)
			HStack(spacing: 4) {
				Image(systemName: deltaIcon)
					.font(.caption)
				Text(deltaText)
					.font(.caption)
			}
			.foregroundStyle(deltaColor)
			Spacer()
		}
		.padding()
		.containerBackground(for: .widget) {
			Color.clear
		}
	}
    
	private var deltaIcon: String {
		if entry.delta < 0 { return "arrow.down.circle.fill" }
		if entry.delta > 0 { return "arrow.up.circle.fill" }
		return "equal.circle.fill"
	}
    
	private var deltaText: String {
		String(format: "%+.1f", entry.delta)
	}
    
	private var deltaColor: Color {
		if entry.delta < 0 { return .green }
		if entry.delta > 0 { return .orange }
		return .blue
	}
}

struct MediumWidgetView: View {
	let entry: WidgetTimelineEntry
    
	var body: some View {
		HStack(spacing: 16) {
			VStack(alignment: .leading, spacing: 8) {
				Text("Current")
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(String(format: "%.1f", entry.weight))
					.font(.system(size: 32, weight: .bold, design: .rounded))
				HStack(spacing: 4) {
					Image(systemName: deltaIcon)
						.font(.caption)
					Text(deltaText)
						.font(.caption)
				}
				.foregroundStyle(deltaColor)
				Text(entry.unit.symbol)
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
			Spacer()
			VStack(spacing: 8) {
				Text("Trend")
					.font(.caption)
					.foregroundStyle(.secondary)
				Image(systemName: trendIcon)
					.font(.system(size: 32))
					.foregroundStyle(trendColor)
				Text(trendText)
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
		}
		.padding()
		.containerBackground(for: .widget) {
			Color.clear
		}
	}
    
	private var deltaIcon: String {
		if entry.delta < 0 { return "arrow.down.circle.fill" }
		if entry.delta > 0 { return "arrow.up.circle.fill" }
		return "equal.circle.fill"
	}
    
	private var deltaText: String {
		String(format: "%+.1f", entry.delta)
	}
    
	private var deltaColor: Color {
		if entry.delta < 0 { return .green }
		if entry.delta > 0 { return .orange }
		return .blue
	}
    
	private var trendIcon: String {
		switch entry.trend {
		case .downward: return "chart.line.downtrend.xyaxis"
		case .upward: return "chart.line.uptrend.xyaxis"
		case .stable: return "chart.line.flattrend.xyaxis"
		}
	}
    
	private var trendText: String {
		entry.trend.description
	}
    
	private var trendColor: Color {
		switch entry.trend {
		case .downward: return .green
		case .upward: return .orange
		case .stable: return .blue
		}
	}
}

#Preview(as: .systemSmall) {
	TrimlyWidget()
} timeline: {
	WidgetTimelineEntry(
		date: Date(),
		weight: 180.0,
		unit: .pounds,
		delta: -2.5,
		trend: .downward
	)
}

#Preview(as: .systemMedium) {
	TrimlyWidget()
} timeline: {
	WidgetTimelineEntry(
		date: Date(),
		weight: 180.0,
		unit: .pounds,
		delta: -2.5,
		trend: .downward
	)
}
