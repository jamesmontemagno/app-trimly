import SwiftUI

struct ChartSelectionSummary: View {
    let point: ChartDataPoint?
    let note: String?
    let unit: WeightUnit
    let precision: Int
    let clearSelection: () -> Void

    var body: some View {
        Group {
            if let point {
                Button(action: clearSelection) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.Charts.selectionTitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(point.date, format: .dateTime.month(.abbreviated).day().year())
                                    .font(.headline)
                            }
                            Spacer()
                            Text(InsightFormatting.weight(point.weight, unit: unit, precision: precision))
                                .font(.title3.weight(.semibold))
                                .multilineTextAlignment(.trailing)
                        }
                        if let note {
                            Label(note, systemImage: "note.text")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.Charts.selectionTitle))
                .accessibilityValue(
                    Text(point.date, format: .dateTime.month(.abbreviated).day().year())
                    + Text(", \(InsightFormatting.weight(point.weight, unit: unit, precision: precision))")
                    + Text(note.map { ", \($0)" } ?? "")
                )
                .accessibilityHint(Text(L10n.Common.closeButton))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .accessibilityHidden(true)
                    Text(L10n.Charts.tapToShowDotsHint)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .transition(.opacity)
    }
}
