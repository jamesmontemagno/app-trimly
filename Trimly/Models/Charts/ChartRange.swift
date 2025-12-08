//
//  ChartRange.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import Foundation

enum ChartRange: String, CaseIterable {
	case week = "Week"
	case month = "Month"
	case quarter = "Quarter"
	case year = "Year"

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
		}
	}
}
