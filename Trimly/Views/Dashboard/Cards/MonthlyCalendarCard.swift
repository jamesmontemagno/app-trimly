//
//  MonthlyCalendarCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct MonthlyCalendarCard: View {
	let weightMap: [Date: String]
	
	var body: some View {
		let dates = Set(weightMap.keys)
		
		return VStack(alignment: .leading, spacing: 8) {
			Text(L10n.Dashboard.monthlyCalendar)
				.font(.subheadline)
				.foregroundStyle(.secondary)
			
			MonthCalendarView(
				datesWithEntries: dates,
				weightTextProvider: { date in weightMap[WeightEntry.normalizeDate(date)] }
			)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}
