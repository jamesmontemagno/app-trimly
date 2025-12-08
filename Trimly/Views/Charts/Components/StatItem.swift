//
//  StatItem.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct StatItem: View {
	let label: String
	let value: String
	let color: Color
	
	var body: some View {
		VStack(spacing: 2) {
			Text(label)
				.font(.caption2)
				.foregroundStyle(.secondary)
			
			Text(value)
				.font(.subheadline.bold())
				.foregroundStyle(color)
		}
	}
}
