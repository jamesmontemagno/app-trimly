# My Weight

A modern, supportive weight tracking app for iOS and macOS built with SwiftUI and SwiftData.

## Overview

My Weight is designed to be your mindful companion for weight tracking, featuring:

- **Multi-entry per day** with flexible daily aggregation (latest or average)
- **Comprehensive analytics** including moving averages, EMA, and trend analysis
- **Goal tracking** with intelligent projections and estimated goal dates
- **Consistency scoring** to help build healthy habits
- **Beautiful charts** with minimalist and analytical display modes
- **HealthKit integration** for seamless data import and ongoing sync
- **Adaptive reminders** that learn from your logging patterns
- **Notes per entry** for contextual tracking
- **iCloud sync** via SwiftData for multi-device support
- **Data export** to CSV for portability
- **Editable history** with note search, date/source filters, and reversible hiding
- **Weekly and monthly recaps**, custom-period comparisons, and optional goal deadlines
- **Device-local dashboard layouts and weight privacy**, plus quick logging from reminders and Shortcuts

## Features

### Core Functionality

- **Dashboard View**: Today's weight, 7-day sparkline, progress metrics, consistency score, and trend summary
- **Timeline View**: Searchable history grouped by day, entry details, manual measurement editing, notes, source/date filters, and hidden-entry review
- **Charts View**: Interactive charts with week/month/quarter/year, all-time, since-goal, and custom ranges; note markers open the day's measurements
- **Settings**: Full customization of units, aggregation, reminders, and data management
- **Portability**: CSV file export/import with mapping and duplicate review, plus previewable PDF progress reports (Pro)
- **Quick logging**: Reminder actions, a Shortcuts action, widget links, and macOS Command-N open the entry form without automatically saving a weight
- **Widgets**: Small/medium widgets and iOS accessory families use a derived App Group snapshot; see [widget integration](docs/WIDGET_IMPLEMENTATION_PLAN.md)

### Analytics

- Simple Moving Average (configurable period, default 7 days)
- Exponential Moving Average (EMA)
- Calendar-day linear regression for trend analysis, with sparse/stale-data guardrails
- Goal projection with estimated completion date
- Consistency score (rolling window, default 30 days)
- Recaps compare equal elapsed calendar-day windows; shorter previous months cap both windows
- Moving average periods count **logging days**, not missing calendar days
- Goal pace describes the relationship between recorded trends and a user-selected date, not a recommended rate of weight change

### Data Model

All data is stored using SwiftData with iCloud sync enabled:

- **WeightEntry**: Individual weight measurements with timestamps, notes, and source tracking
- **Goal**: Active and historical goals with completion tracking
- **AppSettings**: User preferences and app configuration
- **Achievement**: Progress and unlock state for stable achievement keys

The enhancement set does not add persisted models, properties, relationships, or stored enum cases. Dashboard order and privacy preferences live in device-local UserDefaults and do not sync through CloudKit. Widget snapshots are disposable caches, not a second database.

Manual measurements can be edited. Imported HealthKit measurements support app-local notes and hiding, but their weight/time remain read-only. App edits and deletions do not update Apple Health, and deleted imports can return. CSV imports create manual measurements; they do not restore HealthKit identity, goals, achievements, or hidden state. CSV is not a full backup.

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- **Development platform: macOS** (required for SwiftUI/SwiftData frameworks)

## Architecture

Weigh follows modern iOS/macOS development best practices:

- **SwiftUI** for declarative UI
- **SwiftData** for persistent storage with iCloud sync
- **MVVM pattern** with observable data managers
- **Modular design** with separated concerns (Models, Views, Services)
- **Comprehensive analytics** in dedicated service layer

## Project Structure

```
app-trimly/
├── TrimTally.xcodeproj/                # Shared iOS + macOS project and widget extension
├── Trimly/                             # App sources
│   ├── TrimlyApp.swift                 # App entry point (@main)
│   ├── Trimly.swift                    # Shared scene setup
│   ├── Models/                         # SwiftData @Model types
│   ├── Services/                       # DataManager, analytics, HealthKit, reminders
│   ├── Views/                          # SwiftUI screens + Components/
│   ├── Localization/                   # L10n helpers + xcstrings catalog
│   ├── Widget/                         # WidgetKit extension sources
│   ├── Assets.xcassets                 # Shared asset catalog
│   ├── LaunchScreen.storyboard         # Launch experience
│   ├── Trimly.entitlements             # Debug entitlements
│   └── TrimlyRelease.entitlements      # Release entitlements
├── TrimlyTests/                        # XCTest target (unit tests)
│   ├── TrimlyTests.swift
│   ├── DataManagerTests.swift
│   └── WeightAnalyticsTests.swift
├── TrimlyUITests/                      # UI test target
│   ├── TrimlyUITests.swift
│   └── TrimlyUITestsLaunchTests.swift
├── docs/                               # Project documentation set
└── README.md, CONTRIBUTING.md, etc.    # Repo-level docs
```

## Getting Started

### Build & Run in Xcode (Recommended)

1. Clone the repository:
	```bash
	git clone https://github.com/jamesmontemagno/app-trimly.git
	cd app-trimly
	```
2. Open the project:
	```bash
	open TrimTally.xcodeproj
	```
	or launch Xcode and select **File → Open...**.
3. Choose the `TrimTally` scheme and a destination:
	- **iOS**: Any simulator or connected device
	- **macOS**: `My Mac`
4. Press `⌘R` to build and run, `⌘U` to run unit tests.

### Command-Line Builds (CI / automation)

```bash
git clone https://github.com/jamesmontemagno/app-trimly.git
cd app-trimly

xcodebuild -scheme TrimTally \
			  -destination 'platform=iOS Simulator,name=iPhone 17' \
			  clean test
```

## Features Implementation Status

### Version 1.2 (Current)

- [x] Core SwiftData models (WeightEntry, Goal, AppSettings)
- [x] Multi-entry per day logging with daily aggregation controls
- [x] Dashboard, Timeline, Charts, and Settings experiences
- [x] Moving average, EMA, and regression analytics
- [x] Goal tracking with projections and consistency scoring
- [x] CSV export plus full data management tooling
- [x] HealthKit import, historical backfill, and background sync
- [x] Adaptive reminders and notification scheduling
- [x] Micro celebrations, plateau detection, and contextual notes
- [x] Widgets (small + medium), localization, and iCloud sync
- [x] Manual entry editing, day drill-down, search/filters, and hide/unhide
- [x] Calendar-aware trends, weekly/monthly recaps, and period comparisons
- [x] Optional goal deadlines, descriptive pace, and goal-history charts
- [x] Device-local dashboard customization and weight privacy
- [x] CSV mapping/import review, actual file export, and PDF progress reports
- [x] Quick-log routing, Shortcuts, macOS menu command, and accessory widgets

### Future Enhancements

- [ ] Apple Watch companion + complications
- [ ] Larger widget layouts
- [ ] Spotlight integration and direct parameterized Shortcuts logging
- [ ] Manual daily override tooling
- [ ] Full versioned backup/restore beyond measurement CSV

## Data Privacy

Weigh respects your privacy:

- All data stored locally with optional iCloud sync
- No third-party analytics or tracking
- HealthKit data handled securely with background sync
- Full data export and deletion capabilities

## Testing

Run the test suite:

```bash
xcodebuild -scheme TrimTally -destination 'platform=macOS,arch=arm64' test
```

Xcode and Apple SDKs are required; the SwiftUI/SwiftData application cannot be built on Linux. Configure signing for both the app and `TrimTallyWidget`, including their shared App Group, before device deployment.

Tests cover:
- Weight analytics calculations (moving averages, EMA, regression)
- Data management operations (CRUD for entries and goals)
- Consistency score computation
- Goal projection algorithms
- Entry edits, visibility, import validation, and presentation preferences
- Calendar gaps, recaps, comparisons, CSV parsing/mapping, and reports
- Quick-log routing, HealthKit duplicate matching, and widget snapshots

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Localization

Weigh is fully localized in three languages:
- **English** (primary) - 474 strings
- **Spanish** (Español) - 474 strings (100% complete)
- **French** (Français) - 474 strings (100% complete)

All user-facing strings are stored in `Trimly/Localization/Localizable.xcstrings` using the modern String Catalog format. The app automatically adapts to the device's language settings. All translations have been professionally verified to ensure accuracy and natural phrasing.

## License

See [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with modern Apple technologies:
- SwiftUI for beautiful, responsive interfaces
- SwiftData for seamless data persistence
- Swift Charts for elegant visualizations
- HealthKit for health data integration
- WidgetKit for home screen widgets

---

**Weigh** - Your supportive companion for mindful weight tracking.
