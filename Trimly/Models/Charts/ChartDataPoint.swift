//
//  ChartDataPoint.swift
//  My Weight
//
//  Created by Trimly on 12/7/2025.
//

import Foundation

struct ChartDataPoint: Identifiable, Hashable {
	let id: String
	let date: Date
	let weight: Double
	
	init(date: Date, weight: Double) {
		self.date = date
		self.weight = weight
		let dateBits = date.timeIntervalSinceReferenceDate.bitPattern
		let weightBits = weight.bitPattern
		self.id = "\(dateBits)-\(weightBits)"
	}

	static func nearest(to date: Date, in points: [ChartDataPoint]) -> ChartDataPoint? {
		points.min {
			abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
		}
	}
}
