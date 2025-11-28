# Trimly API Documentation

This document describes the internal APIs and architecture of Trimly.

## Table of Contents

- [Data Models](#data-models)
- [Services](#services)
- [Views](#views)
- [Analytics](#analytics)

## Data Models

All models use SwiftData's `@Model` macro for persistence and iCloud sync.

### WeightEntry

Represents a single weight measurement.

```swift
@Model
final class WeightEntry {
    var id: UUID
    var timestamp: Date
    var normalizedDate: Date
    var weightKg: Double
    var displayUnitAtEntry: WeightUnit
    var source: EntrySource
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isHidden: Bool
}
```

**Properties:**
- `id`: Unique identifier
- `timestamp`: Exact time of measurement
- `normalizedDate`: Start of day (for daily grouping)
- `weightKg`: Weight stored in kilograms (canonical unit)
- `displayUnitAtEntry`: Unit shown when entry was created
- `source`: `.manual` or `.healthKit`
- `notes`: Optional user notes
- `createdAt`: Entry creation time
- `updatedAt`: Last modification time
- `isHidden`: True for HealthKit duplicates

**Methods:**
- `static func normalizeDate(_ date: Date) -> Date`: Normalize to day boundary
- `var displayValue: Double`: Get weight in original unit

### Goal

Represents a weight goal (single active, historical archive).

```swift
@Model
final class Goal {
    var id: UUID
    var targetWeightKg: Double
    var startDate: Date
    var targetDate: Date?
    var isActive: Bool
    var completedDate: Date?
    var completionReason: CompletionReason?
    var startingWeightKg: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}
```

**Methods:**
- `func archive(reason: CompletionReason)`: Mark goal as inactive

### AppSettings

Singleton for app preferences.

```swift
@Model
final class AppSettings {
    var preferredUnit: WeightUnit
    var dailyAggregationMode: DailyAggregationMode
    var reminderTime: Date?
    var chartMode: ChartMode
    var healthKitEnabled: Bool
    // ... additional settings
}
```

## Services

### DataManager

Central service for all data operations.

```swift
@MainActor
final class DataManager: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    @Published var settings: AppSettings?
}
```

**Entry Management:**
```swift
func addWeightEntry(
    weightKg: Double,
    timestamp: Date = Date(),
    unit: WeightUnit,
    notes: String? = nil,
    source: EntrySource = .manual
) throws

func fetchAllEntries() -> [WeightEntry]
func fetchEntriesForDate(_ date: Date) -> [WeightEntry]
func deleteEntry(_ entry: WeightEntry) throws
func updateEntry(_ entry: WeightEntry, notes: String?) throws
```

**Goal Management:**
```swift
func setGoal(
    targetWeightKg: Double,
    startingWeightKg: Double?,
    targetDate: Date? = nil,
    notes: String? = nil
) throws

func fetchActiveGoal() -> Goal?
func fetchGoalHistory() -> [Goal]
func completeGoal(reason: CompletionReason) throws
```

**Analytics:**
```swift
func getDailyWeights(mode: DailyAggregationMode? = nil) -> [(date: Date, weight: Double)]
func getCurrentWeight() -> Double?
func getStartWeight() -> Double?
func getConsistencyScore() -> Double?
func getTrend() -> WeightAnalytics.TrendDirection
func getGoalProjection() -> Date?
```

**Data Management:**
```swift
func exportToCSV() -> String
func deleteAllData() throws
```

### WeightAnalytics

Static analytics functions.

**Daily Aggregation:**
```swift
static func aggregateByDay(
    entries: [WeightEntry],
    mode: DailyAggregationMode
) -> [Date: Double]
```

**Smoothing:**
```swift
static func calculateMovingAverage(
    dailyWeights: [(date: Date, weight: Double)],
    period: Int
) -> [(date: Date, value: Double)]

static func calculateEMA(
    dailyWeights: [(date: Date, weight: Double)],
    period: Int
) -> [(date: Date, value: Double)]
```

**Consistency:**
```swift
static func calculateConsistencyScore(
    entries: [WeightEntry],
    windowDays: Int
) -> Double?
```

**Trends:**
```swift
enum TrendDirection {
    case downward, upward, stable
}

static func classifyTrend(
    dailyWeights: [(date: Date, weight: Double)],
    stabilityThreshold: Double = 0.02
) -> TrendDirection
```

**Regression:**
```swift
struct LinearRegressionResult {
    let slope: Double?
    let intercept: Double?
    let correlation: Double?
}

static func calculateLinearRegression(
    dailyWeights: [(date: Date, weight: Double)]
) -> LinearRegressionResult
```

**Projection:**
```swift
static func calculateGoalProjection(
    dailyWeights: [(date: Date, weight: Double)],
    targetWeightKg: Double,
    minDays: Int = 10,
    stabilityThreshold: Double = 0.02
) -> Date?
```

## Views

### DashboardView

Main dashboard showing today's summary.

**Components:**
- Today's weight card (large display)
- Mini sparkline (last 7 days)
- Progress summary (deltas and percentage)
- Consistency score badge
- Trend summary
- Goal projection (if available)

**Actions:**
- Add new entry (+ button)
- Show celebrations (automatic)

### TimelineView

Chronological list of all entries.

**Features:**
- Grouped by day
- Shows daily aggregated value in header
- Swipe to delete entries
- Source badges (HealthKit icon)
- Notes preview

### ChartsView

Interactive weight visualization.

**Controls:**
- Range picker (Week/Month/Quarter/Year)
- Settings button (chart customization)

**Chart Elements:**
- Raw weight line (blue, smooth interpolation)
- Moving average overlay (orange, dashed)
- EMA overlay (purple, dotted)
- Goal line (green, dashed horizontal)
- Interactive tooltips (analytical mode)

**Settings:**
- Chart mode toggle (minimalist/analytical)
- Show/hide moving average
- Configure MA period (3-30 days)
- Show/hide EMA
- Configure EMA period (3-30 days)

### SettingsView

App configuration.

**Sections:**
- Units (weight unit, decimal precision)
- Goal (set/change goal, view history)
- Daily aggregation mode
- Reminders (enable, time, adaptive)
- Consistency score window
- Data (export CSV, delete all)
- About (version, privacy, terms)

### OnboardingView

First-run experience (6 pages).

**Flow:**
1. Welcome screen
2. Unit selection
3. Starting weight (optional)
4. Goal setting (optional)
5. Reminder opt-in
6. EULA acceptance

### AddWeightEntryView

Quick entry creation sheet.

**Fields:**
- Weight (numeric input with unit)
- Date/Time picker
- Notes (optional, multi-line)

**Validation:**
- Weight must be > 0
- Format validation for numeric input

## Analytics

### Moving Average (SMA)

Simple Moving Average calculation:

```
MA(n) = (x₁ + x₂ + ... + xₙ) / n
```

Where `n` is the period (default 7 days).

### Exponential Moving Average (EMA)

```
EMA(t) = α × x(t) + (1 - α) × EMA(t-1)
α = 2 / (period + 1)
```

More responsive to recent changes than SMA.

### Consistency Score

```
Score = (days_with_entries / total_days_in_window) × 100%
```

Default window: 30 days
Minimum: 7 days of data required

### Linear Regression

Using least squares method:

```
slope = Σ[(x - x̄)(y - ȳ)] / Σ[(x - x̄)²]
intercept = ȳ - slope × x̄
```

Where:
- x = day index
- y = weight
- x̄, ȳ = means

### Goal Projection

1. Calculate linear regression on daily weights
2. Exclude last 2 days if volatility > 5%
3. Require minimum data points (default 10)
4. Calculate: `days_to_goal = (target - current) / slope`
5. Return: `current_date + days_to_goal`

**Gating Conditions:**
- Minimum days of data
- Slope direction matches goal direction
- Slope magnitude >= stability threshold
- Distance to goal >= 0.5 kg

## Enumerations

### WeightUnit
```swift
enum WeightUnit: String, Codable {
    case kilograms = "kg"
    case pounds = "lb"
}
```

### EntrySource
```swift
enum EntrySource: String, Codable {
    case manual
    case healthKit
}
```

### DailyAggregationMode
```swift
enum DailyAggregationMode: String, Codable {
    case latest   // Most recent entry of the day
    case average  // Mean of all entries
}
```

### ChartMode
```swift
enum ChartMode: String, Codable {
    case minimalist  // Clean, no grid/axes
    case analytical  // Full grid, axes, tooltips
}
```

### CompletionReason
```swift
enum CompletionReason: String, Codable {
    case achieved   // Goal reached
    case changed    // New goal set
    case abandoned  // User gave up
}
```

## Data Flow

1. **User Input** → AddWeightEntryView
2. **Validation** → DataManager.addWeightEntry()
3. **Storage** → SwiftData ModelContext
4. **iCloud Sync** → Automatic (ModelConfiguration)
5. **Analytics** → WeightAnalytics calculations
6. **Display** → Views (Dashboard, Timeline, Charts)

## Testing

All analytics functions have comprehensive tests:

- Moving average correctness
- EMA calculation
- Consistency score edge cases
- Trend classification
- Linear regression
- Goal projection logic

See `Tests/TrimlyTests/` for implementation.

## Performance Considerations

- Daily aggregation cached in DataManager
- Chart data filtered by range before display
- SwiftData automatic batching for large datasets
- Lazy loading in Timeline (SwiftUI List)
- Debouncing for rapid user input

## Future Enhancements

Planned API additions:

- HealthKit sync service
- Notification service (reminders)
- Widget data provider
- Celebration engine
- Plateau detection
- Export formats (JSON, PDF)
