import Foundation

/// An immutable, notes-free snapshot for a shareable progress report.
struct WeightReport {
    struct Point: Identifiable {
        let date: Date
        let weightKg: Double
        var id: Date { date }
    }

    struct ShareCheckInSnapshot {
        struct Day: Identifiable {
            let date: Date
            let weightKg: Double?
            let hasCheckIn: Bool
            var id: Date { date }
        }

        struct GraphPoint: Identifiable {
            let date: Date
            let weightKg: Double
            let segment: Int
            var id: Date { date }
        }

        let days: [Day]
        let goalWeightKg: Double?
        let goalStartingWeightKg: Double?
        let currentWeightKg: Double?
        let changeKg: Double?
        let unit: WeightUnit
        let decimalPrecision: Int

        var checkedInDays: Int { days.filter(\.hasCheckIn).count }
        var graphPoints: [GraphPoint] {
            var segment = 0
            var previousIndex: Int?
            return days.enumerated().compactMap { index, day in
                guard let weightKg = day.weightKg else { return nil }
                if let previousIndex, index != previousIndex + 1 {
                    segment += 1
                }
                previousIndex = index
                return GraphPoint(date: day.date, weightKg: weightKg, segment: segment)
            }
        }
        var goalProgress: Double? {
            guard let currentWeightKg, let goalWeightKg, let goalStartingWeightKg else { return nil }
            let totalChange = goalWeightKg - goalStartingWeightKg
            if abs(totalChange) < 0.000_001 {
                return abs(currentWeightKg - goalWeightKg) <= 0.05 ? 1 : nil
            }
            let progress = (currentWeightKg - goalStartingWeightKg) / totalChange
            guard progress.isFinite else { return nil }
            let clamped = min(1, max(0, progress))
            return clamped <= 0 ? 0 : clamped
        }

        init(
            entries: [WeightEntry],
            goal: Goal?,
            unit: WeightUnit,
            aggregation: DailyAggregationMode,
            decimalPrecision: Int,
            calendar: Calendar = .current,
            now: Date = Date()
        ) {
            let today = calendar.startOfDay(for: now)
            let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
            let visible = entries.filter {
                !$0.isHidden && $0.weightKg.isFinite && $0.weightKg > 0
                    && $0.timestamp.timeIntervalSinceReferenceDate.isFinite
                    && $0.timestamp <= now
                    && calendar.startOfDay(for: $0.timestamp) <= today
            }
            let grouped = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.timestamp) }
            let aggregated = grouped.reduce(into: [Date: Double]()) { result, item in
                let values = item.value.sorted { $0.timestamp < $1.timestamp }.map(\.weightKg)
                switch aggregation {
                case .latest:
                    result[item.key] = values.last
                case .average:
                    let average = values.reduce(0, +) / Double(values.count)
                    if average.isFinite { result[item.key] = average }
                }
            }
            days = dates.map { date in
                Day(date: date, weightKg: aggregated[date], hasCheckIn: visible.contains {
                    calendar.startOfDay(for: $0.timestamp) == date
                })
            }
            goalWeightKg = goal.map(\.targetWeightKg).flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
            goalStartingWeightKg = goal?.startingWeightKg.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
            currentWeightKg = days.reversed().compactMap(\.weightKg).first
            let weighted = days.compactMap(\.weightKg)
            changeKg = weighted.count >= 2 ? weighted.last! - weighted.first! : nil
            self.unit = unit
            self.decimalPrecision = min(2, max(1, decimalPrecision))
        }

        func displayValue(_ kg: Double) -> Double {
            unit.convert(fromKg: kg)
        }

        func graphValue(_ kg: Double, normalized: Bool) -> Double {
            guard normalized, let baseline = graphPoints.first?.weightKg else {
                return displayValue(kg)
            }
            return displayValue(kg - baseline)
        }

        func chartYDomain(normalized: Bool, includeGoal: Bool) -> ClosedRange<Double>? {
            var values = graphPoints.map { graphValue($0.weightKg, normalized: normalized) }
            if includeGoal, !normalized, let goalWeightKg {
                values.append(displayValue(goalWeightKg))
            }
            guard let minimum = values.min(), let maximum = values.max() else { return nil }
            let span = maximum - minimum
            let minimumPadding = abs(displayValue(0.5))
            let padding = max(span * 0.15, minimumPadding)
            return (minimum - padding)...(maximum + padding)
        }

        func formattedWeight(_ kg: Double, signed: Bool = false) -> String {
            let value = displayValue(kg)
            let text = signed
                ? value.formatted(.number.precision(.fractionLength(decimalPrecision)).sign(strategy: .always()))
                : value.formatted(.number.precision(.fractionLength(decimalPrecision)))
            return "\(text) \(unit.symbol)"
        }
    }

    let points: [Point]
    let entryCount: Int
    let unit: WeightUnit
    let goalWeightKg: Double?
    let aggregation: DailyAggregationMode
    let decimalPrecision: Int

    var firstWeightKg: Double? { points.first?.weightKg }
    var latestWeightKg: Double? { points.last?.weightKg }
    var changeKg: Double? {
        guard let firstWeightKg, let latestWeightKg else { return nil }
        return latestWeightKg - firstWeightKg
    }
    var averageKg: Double? {
        guard !points.isEmpty else { return nil }
        return points.reduce(0) { $0 + $1.weightKg / Double(points.count) }
    }

    init(
        entries: [WeightEntry],
        unit: WeightUnit,
        aggregation: DailyAggregationMode = .latest,
        goalWeightKg: Double? = nil,
        decimalPrecision: Int = 1
    ) {
        let visible = entries.filter {
            !$0.isHidden && $0.weightKg.isFinite && $0.weightKg > 0
                && $0.timestamp.timeIntervalSinceReferenceDate.isFinite
        }
        points = WeightAnalytics.aggregateByDay(entries: visible, mode: aggregation)
            .map { Point(date: $0.key, weightKg: $0.value) }
            .filter { $0.weightKg.isFinite }
            .sorted { $0.date < $1.date }
        entryCount = visible.count
        self.unit = unit
        self.aggregation = aggregation
        self.decimalPrecision = min(2, max(1, decimalPrecision))
        self.goalWeightKg = goalWeightKg.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
    }

    func formattedWeight(_ kg: Double, signed: Bool = false) -> String {
        let value = unit.convert(fromKg: kg)
        let text = signed
            ? value.formatted(.number.precision(.fractionLength(decimalPrecision)).sign(strategy: .always()))
            : value.formatted(.number.precision(.fractionLength(decimalPrecision)))
        return "\(text) \(unit.symbol)"
    }
}
