# Copilot Instructions for TrimTally

## Project Overview
TrimTally is a weight tracking app for iOS 17+ and macOS 14+ built with Swift 6, SwiftUI, and SwiftData. It supports multi-entry-per-day logging, analytics (SMA, EMA, linear regression), goal tracking, and iCloud sync.

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

### Appearance / Theming
- Store theme choice (`system`/`light`/`dark`) in `AppSettings.appearance` (enum `AppAppearance`).
- Read the current value in `TrimlyApp` and map it to `.preferredColorScheme(...)` on the root `ContentView`.
- Always default to `.system` so the app follows the OS when the user has not made an explicit choice.

### Testing
- Use `@MainActor` decorator on test methods accessing DataManager or other main-actor APIs
- Create in-memory DataManager in `setUp()`: `dataManager = await DataManager(inMemory: true)`
- Tests in `TrimlyTests/` cover analytics math and CRUD operations—add tests for new calculations

#### Running Tests from CLI / CI
- Run the full test suite on iOS simulator:
	- `xcodebuild -scheme TrimTally -destination 'platform=iOS Simulator,name=iPhone 17' test`
- Run only a specific test case (e.g., consistency score analytics):
	- `xcodebuild -scheme TrimTally -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing TrimTallyTests/WeightAnalyticsTests test`
- Run only DataManager tests (macOS or iOS destination):
	- `xcodebuild -scheme TrimTally -destination 'platform=macOS,arch=arm64' -only-testing TrimTallyTests/DataManagerTests test`

#### Running Unit Tests Without Launching Simulators
- Prefer running pure unit tests against a macOS destination to avoid booting iOS simulators:
	- `xcodebuild -scheme TrimTally -destination 'platform=macOS,arch=arm64' test`
- This runs the same `TrimTallyTests` target on macOS only; UI tests that depend on iOS simulators will be skipped.

### Error Handling
- DataManager methods throw for persistence errors—views should wrap in `do-catch` or `try?`
- Display errors via SwiftUI alerts, not print statements
- Example: `try? dataManager.addWeightEntry(...)` for non-critical operations

## Build & Run
- **Xcode**: Open `TrimTally.xcodeproj`, select the `TrimTally` scheme for iOS or macOS, `⌘R`
- **CLI/CI**: Use `xcodebuild -scheme TrimTally -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test` for automated testing
- **Platforms**: Requires macOS for development (SwiftUI/SwiftData dependency)

### CLI Quick Reference
- `xcodebuild -scheme TrimTally -destination 'platform=iOS Simulator,name=iPhone 17' build`
- `xcodebuild -scheme TrimTally -destination 'platform=iOS Simulator,name=iPhone 17' test`
- `xcodebuild -scheme TrimTally -destination 'platform=macOS,arch=arm64' build`
- `xcodebuild -scheme TrimTally -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing TrimTallyTests/WeightAnalyticsTests test`
 - `xcodebuild -scheme TrimTally -destination 'platform=macOS,arch=arm64' -only-testing TrimTallyTests/DataManagerTests test`

## File Organization
```
Trimly/
├── TrimlyApp.swift   # App entry point (iOS + macOS)
├── Models/           # SwiftData @Model classes only
├── Services/         # Business logic (DataManager, WeightAnalytics, HealthKit, Notifications, Celebrations, Plateau)
├── Views/            # SwiftUI views—keep presentation logic minimal
└── Widget/           # WidgetKit extension (TrimTally widgets)

TrimlyTests/          # Unit tests (DataManager, WeightAnalytics, etc.)
```

## Analytics Implementation Notes
- **Linear Regression**: Used for trend detection and goal projection in `WeightAnalytics`
- **Volatility Filter**: Goal projection excludes last 2 days if >5% weight jump
- **Consistency Score**: Rolling window (default 30 days), calculated as `days_with_entries / total_days`
- **Trend Thresholds**: Slope < -0.02 kg/day = downward, > 0.02 = upward, else stable

## Current Limitations & Future Work
- Core HealthKit import/sync, reminders, celebrations, plateau detection, and widgets are implemented for v1.2; see `docs/FEATURE_IMPLEMENTATION_V1.2.md` for details.
- Future ideas (not yet implemented) still live in the roadmap section of `docs/DESIGN_DOCUMENT.md` (e.g., Apple Watch app, more widget sizes, Siri Shortcuts, social features).

## Accessibility Requirements
All UI elements must be accessible to users with disabilities. Follow these guidelines when creating or modifying views:

### VoiceOver Support (Required)
- **Interactive elements**: Add `.accessibilityLabel()` to all buttons, text fields, pickers, and tappable elements
  - Example: `Button { ... } label: { Image(systemName: "plus") }.accessibilityLabel("Add weight entry")`
- **Hints**: Add `.accessibilityHint()` to explain non-obvious actions
  - Example: `.accessibilityHint("Opens form to log a new weight")`
- **Values**: Add `.accessibilityValue()` for state-dependent elements (progress bars, scores, toggles)
  - Example: `.accessibilityValue("\(percentage)%, Excellent consistency")`
- **Decorative images**: Mark with `.accessibilityHidden(true)` if they provide no information
  - Example: Decorative icons in feature rows, background images
- **Complex views**: Use `.accessibilityElement(children: .combine)` to group related content
  - Example: Entry rows that combine time, weight, and notes into single announcement

### Dynamic Type Support (Required)
- **Never use fixed font sizes** for user-visible text—use semantic fonts or `@ScaledMetric`
  - ❌ Bad: `.font(.system(size: 56, weight: .bold))`
  - ✅ Good: `.font(.largeTitle.bold())` or `@ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 56`
- **Critical displays** (weight values, scores, statistics) must scale with user's text size preferences
- **Test at largest size**: Settings > Accessibility > Display & Text Size > Larger Text (AX5)
- **Prefer semantic fonts**: Use `.largeTitle`, `.title`, `.headline`, `.body`, `.caption` over custom sizes

### Reduce Motion Support (Required)
- **Check before animating**: Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion`
- **Conditional animations**: Use `reduceMotion ? nil : .easeInOut` for animation parameters
  - Example: `.animation(reduceMotion ? nil : .easeInOut, value: selectedPoint)`
- **Symbol effects**: Pass `isActive: !reduceMotion` to conditionally enable
  - Example: `.symbolEffect(.bounce, isActive: !reduceMotion)`
- **Transitions**: Prefer simple opacity fades over complex motion when reduce motion is enabled
- **Test**: Enable Reduce Motion in Settings > Accessibility > Motion and verify animations are simplified/disabled

### Color & Contrast (Required)
- **Never use color alone** to convey information—add text labels, icons, or patterns
  - ❌ Bad: Green/red text only for positive/negative trends
  - ✅ Good: Green text + "↓" symbol or "Decreasing" label
- **Use system colors**: Prefer `.primary`, `.secondary`, `.accent` over hardcoded colors for better contrast
- **Check `.secondary` usage**: Ensure readability, especially on `.thinMaterial` backgrounds
- **Opacity**: Avoid very low opacity (<0.3) for informational content
- **WCAG AA**: Aim for 4.5:1 contrast ratio for normal text, 3:1 for large text (18pt+)

### Touch Target Sizes (Required)
- **Minimum 44×44pt**: Ensure all interactive elements meet Apple's minimum tap target size
- **Use default padding**: SwiftUI buttons have adequate padding by default—avoid removing it
- **Chart interactions**: Dots and interactive marks should be sufficiently large or have expanded tap areas
- **Info buttons**: Small icon buttons should have `.frame(minWidth: 44, minHeight: 44)` when needed

### Semantic Structure (Required)
- **Use semantic views**: Prefer `List`, `Section`, `Label`, `Form` over generic `VStack`/`HStack`
- **Headers**: Add `.accessibilityAddTraits(.isHeader)` to section titles for better navigation
- **Navigation**: Ensure logical reading order—VoiceOver should flow naturally top-to-bottom, left-to-right
- **Grouping**: Related content should be grouped together for screen reader users

### Common Patterns & Examples

**Button with icon only:**
```swift
Button {
    showingAddEntry = true
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel("Add weight entry")
.accessibilityHint("Opens form to log a new weight")
```

**Progress indicator with value:**
```swift
ProgressView(value: score)
    .accessibilityLabel("Consistency score")
    .accessibilityValue("\(Int(score * 100))%, Excellent")
```

**Dashboard card with combined accessibility:**
```swift
VStack {
    Text("Current Weight")
    Text(displayWeight)
        .font(.largeTitle.bold()) // ✅ Scales with Dynamic Type
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Current weight")
.accessibilityValue(displayWeight)
```

**Scalable custom font size:**
```swift
struct MyView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 56
    
    var body: some View {
        Text(weight)
            .font(.system(size: weightFontSize, weight: .bold, design: .rounded))
    }
}
```

**Conditional animation:**
```swift
struct MyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    
    var body: some View {
        VStack { ... }
            .animation(reduceMotion ? nil : .spring(), value: isExpanded)
    }
}
```

**Complex row with structured accessibility:**
```swift
HStack {
    Text(displayValue)
    Spacer()
    Text(entry.timestamp, style: .time)
        .foregroundStyle(.secondary)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Weight entry: \(displayValue) at \(timeString)")
.accessibilityValue(entry.notes.isEmpty ? "" : "Notes: \(entry.notes)")
```

### Testing Accessibility
Before submitting changes that affect UI:
1. **Enable VoiceOver** and navigate through your view—verify all elements are announced correctly
2. **Set text size to largest** (AX5) and check for truncation or layout issues
3. **Enable Reduce Motion** and verify animations are simplified or removed
4. **Run Accessibility Inspector** (Xcode > Developer Tools) to audit contrast and hierarchy
5. **Test with color filters** to ensure information isn't conveyed by color alone

## Code Style
- Use Swift naming conventions (camelCase for properties/methods)
- Prefer `guard let` over force unwrapping
- Use `// MARK: -` to organize code sections
- Add doc comments (`///`) for public APIs
- Keep views under 300 lines—extract subviews when needed
 - Prefer small helper views (e.g., status pills, labeled rows) for repeated UI patterns instead of duplicating layout logic.

## Critical Gotchas
- **MainActor isolation**: DataManager must be accessed on main thread—use `@MainActor` or `Task { @MainActor in ... }`
- **Date comparisons**: Always normalize dates for daily logic using `Calendar.current.startOfDay(for:)`
- **Unit conversions**: Double-check kg ↔ lb conversions use `WeightUnit` enum, not hardcoded constants
- **iCloud sync**: Test multi-device scenarios—SwiftData handles conflicts but verify merge behavior
- **StoreKit & ObservableObject**: Always `import SwiftUI` or `import Combine` in `StoreManager` or similar classes. `ObservableObject` and `@Published` are not available in `Foundation` alone.
- **Concurrency & Listeners**: When using `Task.detached` for long-running listeners (e.g., `Transaction.updates`), ensure called methods are `nonisolated` if they don't touch `@MainActor` state, or use `await MainActor.run { ... }`.

## Translations
Never hard code strings in views. Use `Localizable.strings` and `NSLocalizedString` for all user-facing text. Follow existing keys for consistency. Make sure to add new keys to all supported languages.


## After Code Changes
Make sure we build the project to verify there are no errors. 