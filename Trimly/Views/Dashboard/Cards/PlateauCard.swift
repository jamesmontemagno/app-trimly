//
//  PlateauCard.swift
//  TrimTally
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
				
				Text(L10n.Dashboard.plateauDetected)
					.font(.headline)
				
				Spacer()
				
				Button(action: onDismiss) {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
				}
			}
			
			Text(plateau.message)
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
			
			Text(plateau.hint)
				.font(.caption)
				.foregroundStyle(.tertiary)
				.multilineTextAlignment(.center)
				.padding(.top, 4)
		}
		.padding()
		.background(.blue.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}
