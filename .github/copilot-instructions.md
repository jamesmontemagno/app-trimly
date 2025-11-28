# Copilot Instructions for Trimly

## Project Overview
Trimly is a weight tracking app for iOS 17+ and macOS 14+ built with SwiftUI and SwiftData. It supports multi-entry-per-day logging, analytics (SMA, EMA, linear regression), goal tracking, and iCloud sync.

## Core Architecture

### Data Flow Pattern
All data operations flow through `DataManager` (singleton, `@MainActor`-bound):
- Views access via `@EnvironmentObject var dataManager: DataManager`
- Models are SwiftData `@Model` classes (WeightEntry, Goal, AppSettings)
- **Never** directly insert/delete from `modelContext` in views—always use DataManager methods
- DataManager automatically saves after mutations and handles error propagation

### SwiftData Setup
- `ModelContainer` configured in `TrimlyApp` with CloudKit sync: `cloudKitDatabase: .automatic`
- Test code uses `DataManager(inMemory: true)` to avoid persistence
- All fetch operations use `FetchDescriptor` with predicates and sorting—avoid manual filtering

### Key Conventions
1. **Weight Storage**: Always store in kilograms (`weightKg: Double`), convert to display unit via `WeightUnit.convert()`
2. **Date Normalization**: Use `WeightEntry.normalizeDate()` for daily grouping (start of day in local timezone)
3. **Daily Aggregation**: Handled by `WeightAnalytics.aggregateByDay()` using mode from AppSettings
4. **Hidden Entries**: Filter with `.filter { !$0.isHidden }` for analytics—used for HealthKit duplicates

## Common Patterns

### Adding Features
- **New models**: Add to schema in `DataManager.init()`, ensure Codable conformance for primitives
- **New analytics**: Add static methods to `WeightAnalytics`, write unit tests in `WeightAnalyticsTests.swift`
- **New settings**: Add properties to `AppSettings` model, update via `dataManager.updateSettings { ... }`
- **New views**: Inject DataManager via `.environmentObject(dataManager)`, use `@EnvironmentObject` to access

### Testing
- Use `@MainActor` decorator on test methods accessing DataManager
- Create in-memory DataManager in `setUp()`: `dataManager = await DataManager(inMemory: true)`
- Tests in `Tests/TrimlyTests/` cover analytics math and CRUD operations—add tests for new calculations

### Error Handling
- DataManager methods throw for persistence errors—views should wrap in `do-catch` or `try?`
- Display errors via SwiftUI alerts, not print statements
- Example: `try? dataManager.addWeightEntry(...)` for non-critical operations

## Build & Run
- **Xcode**: Open `Package.swift`, select iOS/macOS scheme, `⌘R`
- **CLI**: `swift build` (macOS only), `swift test` for tests
- **Platforms**: Requires macOS for development (SwiftUI/SwiftData dependency)

## File Organization
```
Sources/Trimly/
├── Models/          # SwiftData @Model classes only
├── Services/        # Business logic (DataManager, WeightAnalytics, future HealthKit/Notifications)
├── Views/           # SwiftUI views—keep presentation logic minimal
└── Widget/          # Future WidgetKit extension
```

## Analytics Implementation Notes
- **Linear Regression**: Used for trend detection and goal projection in `WeightAnalytics`
- **Volatility Filter**: Goal projection excludes last 2 days if >5% weight jump
- **Consistency Score**: Rolling window (default 30 days), calculated as `days_with_entries / total_days`
- **Trend Thresholds**: Slope < -0.02 kg/day = downward, > 0.02 = upward, else stable

## Current Limitations & Future Work
- HealthKit integration incomplete (models/service exist, views pending)
- Reminder notifications not implemented (placeholders in AppSettings)
- Widget extension stubbed but non-functional
- See `docs/DESIGN_DOCUMENT.md` v1.1+ roadmap for planned features

## Code Style
- Use Swift naming conventions (camelCase for properties/methods)
- Prefer `guard let` over force unwrapping
- Use `// MARK: -` to organize code sections
- Add doc comments (`///`) for public APIs
- Keep views under 300 lines—extract subviews when needed

## Critical Gotchas
- **MainActor isolation**: DataManager must be accessed on main thread—use `@MainActor` or `Task { @MainActor in ... }`
- **Date comparisons**: Always normalize dates for daily logic using `Calendar.current.startOfDay(for:)`
- **Unit conversions**: Double-check kg ↔ lb conversions use `WeightUnit` enum, not hardcoded constants
- **iCloud sync**: Test multi-device scenarios—SwiftData handles conflicts but verify merge behavior
