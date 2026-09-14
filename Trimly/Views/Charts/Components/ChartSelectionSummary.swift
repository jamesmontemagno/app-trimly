import SwiftUI

struct ChartSelectionSummary: View {
    let point: ChartDataPoint?
    let unit: WeightUnit
    let precision: Int
    let clearSelection: () -> Void

    var body: some View {
        Group {
            if let point {
                Button(action: clearSelection) {
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
                )
                .accessibilityHint(Text(L10n.Common.closeButton))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .accessibilityHidden(true)
                    Text(L10n.Charts.tapToShowDotsHint)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .transition(.opacity)
    }
}
