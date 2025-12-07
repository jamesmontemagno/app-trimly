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
	
	@State private var currentMonth = Date()
	
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
							isToday: isToday(date)
						)
					} else {
						// Empty cell for padding
						Color.clear
							.frame(height: 28)
					}
				}
			}
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
}

private struct DayCell: View {
	let date: Date
	let isCurrentMonth: Bool
	let hasEntry: Bool
	let isToday: Bool
	
	private let calendar = Calendar.current
	
	var body: some View {
		ZStack {
			// Background circle for today
			if isToday {
				Circle()
					.strokeBorder(Color.blue, lineWidth: 1.5)
					.frame(width: 28, height: 28)
			}
			
			// Day number
			Text("\(calendar.component(.day, from: date))")
				.font(.caption)
				.foregroundStyle(isCurrentMonth ? .primary : .tertiary)
				.frame(width: 28, height: 28)
			
			// Indicator dot for entries
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
		.frame(height: 28)
	}
}

#Preview {
	let calendar = Calendar.current
	let today = Date()
	var dates = Set<Date>()
	
	// Add some sample dates
	for day in [0, 1, 3, 5, 7, 10, 12, 15, 18, 20, 25] {
		if let date = calendar.date(byAdding: .day, value: -day, to: today) {
			dates.insert(WeightEntry.normalizeDate(date))
		}
	}
	
	return VStack {
		MonthCalendarView(datesWithEntries: dates)
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
			.padding()
	}
}
