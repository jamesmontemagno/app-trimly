//
//  ChartDataPoint.swift
//  TrimTally
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
}
