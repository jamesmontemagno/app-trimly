//
//  PlateauCard.swift
//  Weigh
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct PlateauCard: View {
	let plateau: PlateauDetectionService.PlateauDetection
	let onDismiss: () -> Void
	
	var body: some View {
		VStack(spacing: 12) {
			HStack {
				Image(systemName: "info.circle.fill")
					.foregroundStyle(.blue)
					.accessibilityHidden(true)
				
				Text(L10n.Dashboard.plateauDetected)
					.font(.headline)
					.accessibilityAddTraits(.isHeader)
				
				Spacer()
				
				Button(action: onDismiss) {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
						.frame(minWidth: 44, minHeight: 44)
				}
				.accessibilityLabel(Text(L10n.Insights.dismissPlateau))
			}
			
			Text(plateau.message)
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
			
			Text(plateau.hint)
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.top, 4)
		}
		.padding()
		.background(.blue.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}
