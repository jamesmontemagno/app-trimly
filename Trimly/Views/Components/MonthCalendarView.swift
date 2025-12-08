//
//  MonthCalendarView.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

/// A compact calendar view showing the current month with indicators for days with weight entries
struct MonthCalendarView: View {
	let datesWithEntries: Set<Date>
	let weightTextProvider: (Date) -> String?

	@State private var currentMonth = Date()
	@State private var selectedDate: IdentifiableDate?

	private let calendar = Calendar.current
	private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
	
	var body: some View {
		VStack(spacing: 12) {
			// Month header
			HStack {
				Text(monthYearString)
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.primary)
				Spacer()
			}
			
			// Days of week
			HStack(spacing: 0) {
				ForEach(daysOfWeek, id: \.self) { day in
					Text(day)
						.font(.caption2)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity)
				}
			}
			.padding(.bottom, 4)
			
			// Calendar grid
			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
				ForEach(calendarDays, id: \.self) { date in
					if let date = date {
						DayCell(
							date: date,
							isCurrentMonth: isInCurrentMonth(date),
							hasEntry: hasEntry(for: date),
							isToday: isToday(date),
							didTap: { handleTap(on: date) }
						)
					} else {
						// Empty cell for padding
						Color.clear
							.frame(height: 28)
					}
				}
			}
		}
			.popover(item: $selectedDate, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) { selection in
				Group {
					if let weightText = weightTextProvider(WeightEntry.normalizeDate(selection.date)) {
						VStack(alignment: .leading, spacing: 8) {
							Text(dateString(selection.date))
								.font(.subheadline.weight(.semibold))
							Text(weightText)
								.font(.title3.bold())
						}
						.padding()
						.frame(maxWidth: 220)
					} else {
						Text("No entry for this day")
							.font(.subheadline)
							.padding()
					}
				}
				.presentationCompactAdaptation(.popover)
			}
	}
	
	private var monthYearString: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMMM yyyy"
		return formatter.string(from: currentMonth)
	}
	
	private var calendarDays: [Date?] {
		guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
			  let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
			return []
		}
		
		var days: [Date?] = []
		let startDate = monthFirstWeek.start
		
		// Calculate the number of weeks we need to display
		let numberOfDays = calendar.dateComponents([.day], from: monthFirstWeek.start, to: monthInterval.end).day ?? 0
		let numberOfWeeks = Int(ceil(Double(numberOfDays + 1) / 7.0))
		
		for weekOffset in 0..<numberOfWeeks {
			for dayOffset in 0..<7 {
				let totalOffset = weekOffset * 7 + dayOffset
				if let date = calendar.date(byAdding: .day, value: totalOffset, to: startDate) {
					days.append(date)
				}
			}
		}
		
		return days
	}
	
	private func isInCurrentMonth(_ date: Date) -> Bool {
		calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
	}
	
	private func hasEntry(for date: Date) -> Bool {
		let normalizedDate = WeightEntry.normalizeDate(date)
		return datesWithEntries.contains(normalizedDate)
	}
	
	private func isToday(_ date: Date) -> Bool {
		calendar.isDateInToday(date)
	}

	private func handleTap(on date: Date) {
		guard hasEntry(for: date) else { return }
		selectedDate = IdentifiableDate(date: date)
	}

	private func dateString(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter.string(from: date)
	}
}

private struct DayCell: View {
	let date: Date
	let isCurrentMonth: Bool
	let hasEntry: Bool
	let isToday: Bool
	let didTap: () -> Void
	
	private let calendar = Calendar.current
	
	var body: some View {
		Button(action: didTap) {
			ZStack {
				if isToday {
					Circle()
						.strokeBorder(Color.blue, lineWidth: 1.5)
						.frame(width: 28, height: 28)
				}

				Text("\(calendar.component(.day, from: date))")
					.font(.caption)
					.foregroundStyle(isCurrentMonth ? .primary : .tertiary)
					.frame(width: 28, height: 28)

				if hasEntry && isCurrentMonth {
					VStack {
						Spacer()
						Circle()
							.fill(Color.green)
							.frame(width: 4, height: 4)
							.offset(y: 8)
					}
					.frame(height: 28)
				}
			}
		}
		.buttonStyle(.plain)
		.frame(height: 28)
	}
}

#Preview {
	VStack {
		MonthCalendarView(
			datesWithEntries: MonthCalendarPreviewData.sampleDates,
			weightTextProvider: { MonthCalendarPreviewData.sampleWeights[$0] }
		)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.padding()
	}
}

private enum MonthCalendarPreviewData {
	static let sampleDates: Set<Date> = {
		let calendar = Calendar.current
		let today = Date()
		var dates = Set<Date>()
		
		for day in [0, 1, 3, 5, 7, 10, 12, 15, 18, 20, 25] {
			if let date = calendar.date(byAdding: .day, value: -day, to: today) {
				dates.insert(WeightEntry.normalizeDate(date))
			}
		}
		return dates
	}()

	static let sampleWeights: [Date: String] = {
		let calendar = Calendar.current
		let today = Date()
		var weights = [Date: String]()
		let values: [(Int, Double)] = [
			(0, 72.4), (1, 72.0), (3, 71.8), (5, 72.1), (7, 71.5),
			(10, 71.3), (12, 71.6), (15, 71.0), (18, 70.9), (20, 70.7), (25, 70.5)
		]
		for (day, weight) in values {
			if let date = calendar.date(byAdding: .day, value: -day, to: today) {
				weights[WeightEntry.normalizeDate(date)] = String(format: "%.1f kg", weight)
			}
		}
		return weights
	}()
}
