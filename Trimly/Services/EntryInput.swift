import Foundation

enum EntryInput {
    nonisolated static func weight(_ text: String, locale: Locale = .current) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: locale.decimalSeparator ?? ".")
        let digits = CharacterSet(charactersIn: "0123456789")
        guard !trimmed.isEmpty, parts.count <= 2,
              parts.allSatisfy({ $0.unicodeScalars.allSatisfy(digits.contains) }),
              let value = Double(parts.joined(separator: ".")),
              value.isFinite, value > 0 else { return nil }
        return value
    }

    nonisolated static func display(_ weight: Double, precision: Int) -> String {
        weight.formatted(.number.precision(.fractionLength(min(max(precision, 1), 2))).grouping(.never))
    }
}
