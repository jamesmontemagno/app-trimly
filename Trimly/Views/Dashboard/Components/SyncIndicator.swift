//
//  SyncIndicator.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct SyncIndicator: View {
	enum SyncType {
		case healthKit
		case iCloud
		
		var icon: String {
			switch self {
			case .healthKit: return "heart.fill"
			case .iCloud: return "icloud.and.arrow.down"
			}
		}
		
		var color: Color {
			switch self {
			case .healthKit: return .pink
			case .iCloud: return .blue
			}
		}
		
		var label: LocalizedStringResource {
			switch self {
			case .healthKit: return L10n.Dashboard.syncedToHealthKit
			case .iCloud: return L10n.Dashboard.syncedFromICloud
			}
		}
	}
	
	let type: SyncType
	
	var body: some View {
		HStack(spacing: 6) {
			Image(systemName: type.icon)
				.font(.caption)
				.foregroundStyle(type.color)
			Text(type.label)
				.font(.caption)
				.foregroundStyle(.secondary)
		}
	}
}
