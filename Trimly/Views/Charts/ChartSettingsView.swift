//
//  ChartSettingsView.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct ChartSettingsView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					TrimlyCardSection(
						title: String(localized: L10n.ChartSettings.displayModeTitle),
						description: String(localized: L10n.ChartSettings.displayModeDescription),
						style: .popup
					) {
						Picker(String(localized: L10n.ChartSettings.displayModeTitle), selection: binding(\.chartMode)) {
							Text(L10n.ChartSettings.displayMinimalist).tag(ChartMode.minimalist)
							Text(L10n.ChartSettings.displayAnalytical).tag(ChartMode.analytical)
						}
						.pickerStyle(.segmented)
					}

					TrimlyCardSection(
						title: String(localized: L10n.ChartSettings.trendLayersTitle),
						description: String(localized: L10n.ChartSettings.trendLayersDescription),
						style: .popup
					) {
						Toggle(L10n.ChartSettings.movingAverageToggle, isOn: binding(\.showMovingAverage))
						Text(L10n.ChartSettings.movingAverageInfo)
							.font(.caption)
							.foregroundStyle(.secondary)

						if dataManager.settings?.showMovingAverage == true {
							Divider().padding(.vertical, 10)
							Stepper(value: binding(\.movingAveragePeriod), in: 3...30) {
								VStack(alignment: .leading, spacing: 2) {
									Label(String(localized: L10n.ChartSettings.movingAverageLabel), systemImage: "chart.xyaxis.line")
										.font(.subheadline.weight(.semibold))
									Text(L10n.ChartSettings.daysLabel(dataManager.settings?.movingAveragePeriod ?? 7))
										.font(.caption)
										.foregroundStyle(.secondary)
								}
							}
						}

						Divider().padding(.vertical, 10)

						Toggle(L10n.ChartSettings.emaToggle, isOn: binding(\.showEMA))
						Text(L10n.ChartSettings.emaInfo)
							.font(.caption)
							.foregroundStyle(.secondary)

						if dataManager.settings?.showEMA == true {
							Divider().padding(.vertical, 10)
							Stepper(value: binding(\.emaPeriod), in: 3...30) {
								VStack(alignment: .leading, spacing: 2) {
									Label(String(localized: L10n.ChartSettings.emaLabel), systemImage: "chart.line.flattrend.xyaxis")
										.font(.subheadline.weight(.semibold))
									Text(L10n.ChartSettings.daysLabel(dataManager.settings?.emaPeriod ?? 7))
										.font(.caption)
										.foregroundStyle(.secondary)
								}
							}
						}

						Text(L10n.ChartSettings.overlaysHint)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
				.padding(24)
			}
			.navigationTitle(Text(L10n.ChartSettings.navigationTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.doneButton)) {
						dismiss()
					}
				}
			}
		}
	}
	
	private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
		Binding(
			get: { dataManager.settings?[keyPath: keyPath] ?? AppSettings()[keyPath: keyPath] },
			set: { newValue in
				dataManager.updateSettings { settings in
					settings[keyPath: keyPath] = newValue
				}
			}
		)
	}
}
