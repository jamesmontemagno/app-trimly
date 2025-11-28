//
//  TimelineView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct TimelineView: View {
	@EnvironmentObject var dataManager: DataManager
	@State private var showingAddEntry = false
    
	var body: some View {
		NavigationStack {
			List {
				ForEach(groupedEntries, id: \.date) { group in
					Section {
						ForEach(group.entries) { entry in
							EntryRow(entry: entry)
						}
						.onDelete { indexSet in
							deleteEntries(at: indexSet, in: group.entries)
						}
					} header: {
						DayHeader(date: group.date, entries: group.entries)
					}
				}
			}
			.navigationTitle("Timeline")
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showingAddEntry = true
					} label: {
						Image(systemName: "plus")
					}
				}
			}
			.sheet(isPresented: $showingAddEntry) {
				AddWeightEntryView()
			}
			.overlay {
				if groupedEntries.isEmpty {
					ContentUnavailableView("No Entries Yet",
										   systemImage: "chart.line.uptrend.xyaxis",
										   description: Text("Add your first weight entry to get started"))
				}
			}
		}
	}
    
	private var groupedEntries: [DayGroup] {
		let entries = dataManager.fetchAllEntries()
		let grouped = Dictionary(grouping: entries) { $0.normalizedDate }
		return grouped.map { date, entries in
			DayGroup(date: date,
					 entries: entries.sorted { $0.timestamp > $1.timestamp })
		}
		.sorted { $0.date > $1.date }
	}
    
	private func deleteEntries(at offsets: IndexSet, in entries: [WeightEntry]) {
		for index in offsets {
			let entry = entries[index]
			try? dataManager.deleteEntry(entry)
		}
	}
}

struct DayGroup {
	let date: Date
	let entries: [WeightEntry]
}

struct DayHeader: View {
	let date: Date
	let entries: [WeightEntry]
	@EnvironmentObject var dataManager: DataManager
    
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(date, style: .date)
				.font(.headline)
			if let aggregatedWeight = aggregatedWeight {
				let displayWeight = displayValue(aggregatedWeight)
				Text("Daily: \(displayWeight)")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
	}
    
	private var aggregatedWeight: Double? {
		guard !entries.isEmpty else { return nil }
		let mode = dataManager.settings?.dailyAggregationMode ?? .latest
		switch mode {
		case .latest:
			return entries.first?.weightKg
		case .average:
			let sum = entries.reduce(0.0) { $0 + $1.weightKg }
			return sum / Double(entries.count)
		}
	}
    
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
}

struct EntryRow: View {
	let entry: WeightEntry
	@EnvironmentObject var dataManager: DataManager
    
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(displayValue)
					.font(.title3.bold())
				Spacer()
				Text(entry.timestamp, style: .time)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
            
			HStack {
				if entry.source == .healthKit {
					Label("HealthKit", systemImage: "heart.fill")
						.font(.caption)
						.foregroundStyle(.pink)
				}
				if let notes = entry.notes, !notes.isEmpty {
					Text(notes)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(2)
				}
			}
		}
		.opacity(entry.isHidden ? 0.5 : 1.0)
	}
    
	private var displayValue: String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", entry.weightKg)
		}
		let value = unit.convert(fromKg: entry.weightKg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
}

#Preview {
	TimelineView()
		.environmentObject(DataManager(inMemory: true))
}
