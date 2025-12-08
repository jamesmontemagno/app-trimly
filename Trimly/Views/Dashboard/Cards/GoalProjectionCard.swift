//
//  GoalProjectionCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct GoalProjectionCard: View {
	let projectionDate: Date
	
	var body: some View {
		VStack(spacing: 8) {
			Text(L10n.Dashboard.estimatedGoalDate)
				.font(.subheadline)
				.foregroundStyle(.secondary)
			
			Text(projectionDate, style: .date)
				.font(.title3.bold())
				.foregroundStyle(.purple)
			
			let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: projectionDate).day ?? 0
			Text(L10n.Dashboard.goalArrival(daysUntil))
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}
