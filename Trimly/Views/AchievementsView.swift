//
//  AchievementsView.swift
//  TrimTally
//
//  Created by Trimly on 11/29/25.
//

import SwiftUI
import Combine

struct AchievementsView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var storeManager: StoreManager
	@StateObject private var achievementService = AchievementService()
	
	var body: some View {
		NavigationStack {
			ScrollView {
				LazyVStack(alignment: .leading, spacing: 24) {
					ForEach(groupedSnapshots) { group in
						Section {
							ForEach(group.snapshots) { snapshot in
								AchievementCard(snapshot: snapshot)
							}
						} header: {
							Text(group.category.title)
								.font(.headline)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
					}
					if hasPremiumLock && !storeManager.isPro {
						premiumUpsellHint
					}
				}
				.padding(.horizontal)
			}
			.navigationTitle(Text(L10n.Achievements.navigationTitle))
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button(action: refresh) {
						Image(systemName: "arrow.clockwise")
					}
					.accessibilityLabel(Text(L10n.Common.refresh))
				}
			}
			.onAppear(perform: refresh)
			.onReceive(dataManager.objectWillChange) { _ in
				refresh()
			}
			.onChange(of: storeManager.isPro) { _ in
				refresh()
			}
		}
	}
	
	private var groupedSnapshots: [AchievementCategoryGroup] {
		let groups = Dictionary(grouping: achievementService.snapshots) { $0.descriptor.category }
		return AchievementCategory.allCases.compactMap { category in
			guard let snapshots = groups[category], !snapshots.isEmpty else { return nil }
			return AchievementCategoryGroup(category: category, snapshots: snapshots)
		}
	}
	
	private var hasPremiumLock: Bool {
		achievementService.snapshots.contains { $0.requiresPro }
	}
	
	private var premiumUpsellHint: some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: "star.fill")
				.foregroundStyle(.yellow)
			Text(L10n.Achievements.sectionPremiumHint)
				.font(.callout)
				.foregroundStyle(.secondary)
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
	
	private func refresh() {
		achievementService.refresh(using: dataManager, isPro: storeManager.isPro)
	}
}

private struct AchievementCard: View {
	let snapshot: AchievementSnapshot
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .top) {
				Label {
					Text(snapshot.descriptor.title)
						.font(.headline)
				} icon: {
					Image(systemName: snapshot.descriptor.iconName)
						.symbolRenderingMode(.hierarchical)
				}
				Spacer()
				badgeStack
			}
			if snapshot.requiresPro {
				Text(L10n.Achievements.proUnlockLine)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			} else {
				Text(snapshot.descriptor.detail)
					.font(.subheadline)
					.foregroundStyle(.secondary)
				ProgressView(value: min(max(snapshot.progressValue, 0), 1)) {
					Text(L10n.Achievements.progressLabel)
						.font(.caption)
						.foregroundStyle(.secondary)
				} currentValueLabel: {
					Text(progressDisplay)
						.font(.caption)
				}
				if !snapshot.isUnlocked {
					Text(L10n.Achievements.lockedBadge)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.overlay(alignment: .topTrailing) {
			if snapshot.isUnlocked {
				Image(systemName: "seal.fill")
					.symbolRenderingMode(.palette)
					.foregroundStyle(.green, .white)
					.padding(8)
			}
		}
	}
	
	private var badgeStack: some View {
		HStack(spacing: 6) {
			if snapshot.descriptor.isPremium {
				Text(L10n.Achievements.proBadge)
					.font(.caption.bold())
					.padding(.vertical, 4)
					.padding(.horizontal, 8)
					.background(Color.yellow.opacity(0.15))
					.clipShape(Capsule())
			}
			if snapshot.isUnlocked {
				Image(systemName: "checkmark.seal.fill")
					.foregroundStyle(.green)
			}
		}
	}
	
	private var progressDisplay: String {
		let percent = Int(snapshot.progressValue * 100)
		return "\(percent)%"
	}
}

private struct AchievementCategoryGroup: Identifiable {
	let category: AchievementCategory
	let snapshots: [AchievementSnapshot]
	var id: AchievementCategory { category }
}

#Preview {
	NavigationStack {
		AchievementsView()
			.environmentObject(DataManager(inMemory: true))
			.environmentObject(StoreManager())
	}
}
