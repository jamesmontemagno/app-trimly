# TrimTally

A modern, supportive weight tracking app for iOS and macOS built with SwiftUI and SwiftData.

## Overview

TrimTally is designed to be your mindful companion for weight tracking, featuring:

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

## Features

### Core Functionality

- **Dashboard View**: Today's weight, 7-day sparkline, progress metrics, consistency score, and trend summary
- **Timeline View**: Chronological list of all entries grouped by day with aggregated values
- **Charts View**: Interactive charts with customizable ranges (week, month, quarter, year)
- **Settings**: Full customization of units, aggregation, reminders, and data management

### Analytics

- Simple Moving Average (configurable period, default 7 days)
- Exponential Moving Average (EMA)
- Linear regression for trend analysis
- Goal projection with estimated completion date
- Consistency score (rolling window, default 30 days)

### Data Model

All data is stored using SwiftData with iCloud sync enabled:

- **WeightEntry**: Individual weight measurements with timestamps, notes, and source tracking
- **Goal**: Active and historical goals with completion tracking
- **AppSettings**: User preferences and app configuration

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- **Development platform: macOS** (required for SwiftUI/SwiftData frameworks)

## Architecture

TrimTally follows modern iOS/macOS development best practices:

- **SwiftUI** for declarative UI
- **SwiftData** for persistent storage with iCloud sync
- **MVVM pattern** with observable data managers
- **Modular design** with separated concerns (Models, Views, Services)
- **Comprehensive analytics** in dedicated service layer

## Project Structure

```
app-trimly/
├── TrimTally.xcodeproj/                # Shared iOS + macOS project
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
			  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
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

### Future Enhancements

- [ ] Apple Watch companion + complications
- [ ] Expanded widget sizes and lock screen support
- [ ] Siri Shortcuts and Spotlight integration
- [ ] Manual daily override tooling
- [ ] Goal history visualization and sharing options

## Data Privacy

TrimTally respects your privacy:

- All data stored locally with optional iCloud sync
- No third-party analytics or tracking
- HealthKit data handled securely (when implemented)
- Full data export and deletion capabilities

## Testing

Run the test suite:

```bash
swift test
```

Tests cover:
- Weight analytics calculations (moving averages, EMA, regression)
- Data management operations (CRUD for entries and goals)
- Consistency score computation
- Goal projection algorithms

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

See [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with modern Apple technologies:
- SwiftUI for beautiful, responsive interfaces
- SwiftData for seamless data persistence
- Swift Charts for elegant visualizations
- HealthKit for health data integration (planned)

---

**TrimTally** - Your supportive companion for mindful weight tracking.
