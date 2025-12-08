//
//  ExportView.swift
//  TrimTally
//
//  Created by Trimly on 12/07/2025.
//

import SwiftUI

struct ExportView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
	@State private var csvData: String

	init(initialCSV: String) {
		_csvData = State(initialValue: initialCSV)
	}

	private var hasContent: Bool {
		!csvData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private var entryCount: Int {
		let lines = csvData.split(whereSeparator: { $0 == "\n" || $0 == "\r" })
		return max(lines.count - 1, 0) // ignore header row
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					Text(String(localized: L10n.Export.hint))
						.font(.callout)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.leading)

					if hasContent {
						TrimlyCardContainer(style: .popup) {
							ScrollView(.horizontal, showsIndicators: true) {
								Text(verbatim: csvData)
									.font(.system(.caption, design: .monospaced))
									.multilineTextAlignment(.leading)
									.textSelection(.enabled)
									.frame(maxWidth: .infinity, alignment: .topLeading)
							}
						}
						if entryCount == 0 {
							Text(String(localized: L10n.Export.emptyDescription))
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					} else {
						ContentUnavailableView(
							String(localized: L10n.Export.emptyTitle),
							systemImage: "doc.text.magnifyingglass",
							description: Text(L10n.Export.emptyDescription)
						)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(24)
			}
			.navigationTitle(Text(L10n.Export.navigationTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.doneButton)) { dismiss() }
				}
				ToolbarItem(placement: .primaryAction) {
					ShareLink(item: csvData)
				}
			}
		}
		.onAppear(perform: refreshData)
	}

	private func refreshData() {
		let latest = dataManager.exportToCSV()
		csvData = latest
	}
}
