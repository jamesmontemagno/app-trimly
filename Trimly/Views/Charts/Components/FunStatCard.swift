//
//  FunStatCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct FunStatCard: View {
	let icon: String
	let title: String
	let value: String
	let color: Color
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.title2)
				.foregroundStyle(color)
				.frame(width: 40, height: 40)
				.background(color.opacity(0.1))
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(value)
					.font(.subheadline.bold())
					.lineLimit(2)
					.multilineTextAlignment(.leading)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(Color.secondary.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
}
