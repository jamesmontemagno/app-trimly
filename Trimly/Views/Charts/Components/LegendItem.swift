//
//  LegendItem.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct LegendItem: View {
	let color: Color
	let label: String
	let style: LineStyle
	
	var body: some View {
		HStack(spacing: 4) {
			Capsule()
				.stroke(color, style: legendStroke)
				.frame(width: 24, height: 4)
			
			Text(label)
				.foregroundStyle(.secondary)
		}
	}

	private var legendStroke: StrokeStyle {
		switch style {
		case .solid:
			return StrokeStyle(lineWidth: 2)
		case .dashed:
			return StrokeStyle(lineWidth: 2, dash: [5, 3])
		case .dotted:
			return StrokeStyle(lineWidth: 2, dash: [1, 4])
		}
	}
}
