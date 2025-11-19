# Trimly

A modern, supportive weight tracking app for iOS and macOS built with SwiftUI and SwiftData.

## Overview

Trimly is designed to be your mindful companion for weight tracking, featuring:

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

Trimly follows modern iOS/macOS development best practices:

- **SwiftUI** for declarative UI
- **SwiftData** for persistent storage with iCloud sync
- **MVVM pattern** with observable data managers
- **Modular design** with separated concerns (Models, Views, Services)
- **Comprehensive analytics** in dedicated service layer

## Project Structure

```
Sources/Trimly/
├── Models/
│   ├── WeightEntry.swift       # Weight measurement model
│   ├── Goal.swift              # Goal tracking model
│   └── AppSettings.swift       # App settings model
├── Services/
│   ├── WeightAnalytics.swift   # Analytics calculations
│   └── DataManager.swift       # Data management service
├── Views/
│   ├── ContentView.swift       # Main app navigation
│   ├── DashboardView.swift     # Today's summary
│   ├── TimelineView.swift      # Entry list
│   ├── ChartsView.swift        # Data visualization
│   ├── SettingsView.swift      # Settings & preferences
│   ├── OnboardingView.swift    # First-run experience
│   └── AddWeightEntryView.swift # Entry creation
└── TrimlyApp.swift             # App entry point

Tests/TrimlyTests/
├── WeightAnalyticsTests.swift  # Analytics tests
└── DataManagerTests.swift      # Data management tests
```

## Getting Started

### Building

```bash
# Clone the repository
git clone https://github.com/jamesmontemagno/app-trimly.git
cd app-trimly

# Build with Swift Package Manager
swift build

# Run tests
swift test
```

### Opening in Xcode

1. Open `Package.swift` in Xcode
2. Select the desired scheme (iOS or macOS)
3. Build and run (⌘R)

## Features Implementation Status

### Version 1.0 (Current)

- [x] Core data models (WeightEntry, Goal, AppSettings)
- [x] Multi-entry per day support
- [x] Daily aggregation (latest/average)
- [x] Dashboard with metrics
- [x] Timeline view
- [x] Charts with multiple ranges
- [x] Moving average & EMA smoothing
- [x] Goal management
- [x] Consistency score
- [x] Goal projection
- [x] Trend analysis
- [x] Data export (CSV)
- [x] Onboarding flow
- [x] Settings management
- [x] iCloud sync via SwiftData

### Future Enhancements

- [ ] HealthKit integration (import & sync)
- [ ] Reminder notifications with adaptive behavior
- [ ] Micro celebrations for milestones
- [ ] Home Screen widget
- [ ] Plateau detection hints
- [ ] Manual daily value override
- [ ] Goal history visualization
- [ ] Additional chart customization
- [ ] Localization

## Data Privacy

Trimly respects your privacy:

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

**Trimly** - Your supportive companion for mindful weight tracking.
