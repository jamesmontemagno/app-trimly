# TrimTally Quick Reference

## 🚀 Quick Start

```bash
# Clone and open
git clone https://github.com/jamesmontemagno/app-trimly.git
cd app-trimly
open Trimly.xcodeproj

# Build and run in Xcode
⌘R
```

## 📂 File Organization

```
Trimly/             # App sources (iOS + macOS)
├── Models/         # SwiftData models
├── Services/       # Business logic & analytics
├── Views/          # SwiftUI views
└── Widget/         # WidgetKit extension

TrimlyTests/        # Unit tests
```

## 🎯 Core Concepts

### Data Models

**WeightEntry**
```swift
// Log a weight
let entry = WeightEntry(
    weightKg: 80.0,
    displayUnitAtEntry: .kilograms
)
```

**Goal**
```swift
// Set a goal
let goal = Goal(targetWeightKg: 75.0)
```

**AppSettings**
```swift
// User preferences
settings.preferredUnit = .pounds
settings.dailyAggregationMode = .latest
```

### Using DataManager

```swift
// Add entry
try dataManager.addWeightEntry(
    weightKg: 80.0,
    unit: .kilograms,
    notes: "Morning weight"
)

// Fetch entries
let entries = dataManager.fetchAllEntries()

// Set goal
try dataManager.setGoal(
    targetWeightKg: 75.0,
    startingWeightKg: 80.0
)

// Get analytics
let score = dataManager.getConsistencyScore()
let trend = dataManager.getTrend()
let projection = dataManager.getGoalProjection()
```

### Analytics Functions

```swift
// Moving average
let ma = WeightAnalytics.calculateMovingAverage(
    dailyWeights: weights,
    period: 7
)

// EMA
let ema = WeightAnalytics.calculateEMA(
    dailyWeights: weights,
    period: 7
)

// Trend
let trend = WeightAnalytics.classifyTrend(
    dailyWeights: weights
)
```

## 📊 Views

### Dashboard
- Today's weight
- 7-day sparkline
- Progress metrics
- Consistency score

### Timeline
- All entries by day
- Daily aggregates
- Swipe to delete

### Charts
- Week/Month/Quarter/Year
- Weight line + smoothing
- Goal line
- Statistics

### Settings
- Units & precision
- Goal management
- Aggregation mode
- Export/delete data

## 🧪 Testing

```bash
# In Xcode
⌘U

# From command line (CI)
xcodebuild -scheme Trimly -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

## 📚 Documentation

| File | Purpose |
|------|---------|
| README.md | Overview & quick start |
| API_DOCUMENTATION.md | Complete API reference |
| DESIGN_DOCUMENT.md | Design specifications |
| BUILD_INSTRUCTIONS.md | Build guide |
| CONTRIBUTING.md | How to contribute |
| PROJECT_STRUCTURE.md | Architecture diagrams |
| IMPLEMENTATION_SUMMARY.md | Project summary |

## 🎨 UI Components

### Colors
- **Blue**: Primary actions, weight line
- **Green**: Downward trend, goals
- **Orange**: Moving average, upward trend
- **Purple**: EMA, projections

### Typography
- Large: 34pt (dashboard weight)
- Title: 28pt (headers)
- Body: 17pt (content)
- Caption: 12pt (metadata)

## 🔑 Key Features

✅ Multi-entry per day
✅ Flexible aggregation (latest/average)
✅ Moving averages (SMA & EMA)
✅ Consistency scoring
✅ Goal tracking
✅ Trend analysis
✅ Goal projections
✅ CSV export
✅ iCloud sync

## 📱 Platforms

- iOS 17.0+
- macOS 14.0+

## 🛠️ Requirements

- macOS 14.0+ (for development)
- Xcode 15.0+
- Swift 5.9+

## 🎯 Common Tasks

### Add a Weight Entry
1. Open app
2. Tap + button
3. Enter weight
4. (Optional) Add notes
5. Save

### Set a Goal
1. Settings tab
2. Goal section
3. Tap "Set Goal"
4. Enter target weight
5. Save

### View Charts
1. Charts tab
2. Select range
3. Tap settings for customization

### Export Data
1. Settings tab
2. Data section
3. Tap "Export Data (CSV)"
4. Use share sheet

## 🔍 Troubleshooting

**Build fails on Linux**
→ Use macOS with Xcode (SwiftUI/SwiftData required)

**"No such module SwiftData"**
→ Update to Xcode 15.0+

**iCloud not syncing**
→ Check iCloud is enabled in device settings

## 📖 Further Reading

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Swift Charts Documentation](https://developer.apple.com/documentation/charts)

## 🤝 Contributing

See CONTRIBUTING.md for:
- Code style guidelines
- Testing requirements
- PR process

## 📞 Support

For issues:
1. Check existing GitHub Issues
2. Review documentation
3. Open new issue with details

## 📜 License

See LICENSE file

---

**TrimTally** - Your supportive companion for mindful weight tracking

Version 1.0.0 | Built with SwiftUI & SwiftData
