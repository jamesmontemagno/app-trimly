//
//  CelebrationOverlayView.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct CelebrationOverlayView: View {
	let celebration: CelebrationService.Celebration
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	
	var body: some View {
		VStack(spacing: 16) {
			if #available(macOS 15.0, *) {
				Image(systemName: celebration.iconName)
					.font(.system(size: 60))
					.foregroundStyle(.yellow)
					.symbolEffect(.bounce, isActive: !reduceMotion)
					.accessibilityLabel("Achievement unlocked")
			} else {
				Image(systemName: celebration.iconName)
					.font(.system(size: 60))
					.foregroundStyle(.yellow)
					.accessibilityLabel("Achievement unlocked")
			}
			
			Text(celebration.message)
				.font(.title2.bold())
				.multilineTextAlignment(.center)
				.foregroundStyle(.primary)
		}
		.padding(32)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.shadow(radius: 10)
		.accessibilityElement(children: .combine)
		.accessibilityLabel("Celebration: \(celebration.message)")
	}
}
