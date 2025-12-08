//
//  ChartDataPoint.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import Foundation

struct ChartDataPoint: Identifiable {
	let id = UUID()
	let date: Date
	let weight: Double
}
