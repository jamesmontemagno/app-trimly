//
//  ChartRange.swift
//  My Weight
//
//  Created by Trimly on 12/7/2025.
//

import Foundation

enum ChartRange: String, CaseIterable {
	case week = "Week"
	case month = "Month"
	case quarter = "Quarter"
	case year = "Year"
	case allTime = "AllTime"
	case sinceGoal = "SinceGoal"
	case custom = "Custom"

	var displayName: String {
		switch self {
		case .week:
			return String(localized: L10n.Charts.rangeWeek)
		case .month:
			return String(localized: L10n.Charts.rangeMonth)
		case .quarter:
			return String(localized: L10n.Charts.rangeQuarter)
		case .year:
			return String(localized: L10n.Charts.rangeYear)
		case .allTime:
			return String(localized: L10n.Insights.allTime)
		case .sinceGoal:
			return String(localized: L10n.Insights.sinceGoal)
		case .custom:
			return String(localized: L10n.Insights.customRange)
		}
	}

	func period(
		now: Date = Date(), firstDate: Date?, goalStart: Date?, customStart: Date, customEnd: Date,
		calendar: Calendar = .current
	) -> WeightInsights.Period? {
		guard now.timeIntervalSinceReferenceDate.isFinite else { return nil }
		let today = calendar.startOfDay(for: now)
		let start: Date
		switch self {
		case .week: start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
		case .month: start = calendar.date(byAdding: .month, value: -1, to: today) ?? today
		case .quarter: start = calendar.date(byAdding: .month, value: -3, to: today) ?? today
		case .year: start = calendar.date(byAdding: .year, value: -1, to: today) ?? today
		case .allTime: start = firstDate ?? today
		case .sinceGoal:
			guard let goalStart else { return nil }
			start = goalStart
		case .custom:
			return .inclusive(from: customStart, through: min(customEnd, today), calendar: calendar)
		}
		return .inclusive(from: start, through: today, calendar: calendar)
	}
}
