# Trimly Project Structure

```
app-trimly/
│
├── Package.swift                      # Swift Package Manager manifest
├── .gitignore                         # Git ignore rules
├── LICENSE                            # Project license
│
├── README.md                          # Project overview and quick start
├── CONTRIBUTING.md                    # Contribution guidelines
├── BUILD_INSTRUCTIONS.md              # Detailed build instructions
├── API_DOCUMENTATION.md               # Complete API reference
└── DESIGN_DOCUMENT.md                 # Design specifications and decisions
│
├── Sources/
│   └── Trimly/                        # Main application module
│       │
│       ├── TrimlyApp.swift            # App entry point (@main)
│       ├── Trimly.swift               # Library entry point
│       │
│       ├── Models/                    # SwiftData models
│       │   ├── WeightEntry.swift      # Weight measurement model
│       │   ├── Goal.swift             # Goal tracking model
│       │   └── AppSettings.swift      # User preferences model
│       │
│       ├── Services/                  # Business logic layer
│       │   ├── DataManager.swift      # Data operations service
│       │   └── WeightAnalytics.swift  # Analytics calculations
│       │
│       └── Views/                     # SwiftUI views
│           ├── ContentView.swift      # Root navigation view
│           ├── DashboardView.swift    # Today's summary
│           ├── TimelineView.swift     # Entry history
│           ├── ChartsView.swift       # Data visualization
│           ├── SettingsView.swift     # App settings
│           ├── OnboardingView.swift   # First-run experience
│           └── AddWeightEntryView.swift # Entry creation
│
└── Tests/
    └── TrimlyTests/                   # Unit tests
        ├── WeightAnalyticsTests.swift # Analytics tests
        └── DataManagerTests.swift     # Data manager tests
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                        TrimlyApp                            │
│                     (App Entry Point)                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      ContentView                             │
│           (Navigation & Onboarding Gate)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┬──────────────┐
        ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐
│  Dashboard   │ │ Timeline │ │  Charts  │ │   Settings   │
│     View     │ │   View   │ │   View   │ │     View     │
└──────┬───────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘
       │              │            │                │
       └──────────────┴────────────┴────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │       DataManager            │
        │  (Central Data Service)      │
        └──────────┬───────────────────┘
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌──────────────────┐
│ Weight   │ │   Goal   │ │  AppSettings     │
│  Entry   │ │  Model   │ │     Model        │
└──────────┘ └──────────┘ └──────────────────┘
        │
        └────────────────────────────────────┐
                                             ▼
                              ┌──────────────────────────┐
                              │   WeightAnalytics        │
                              │ (Analytics Calculations) │
                              └──────────────────────────┘
```

## Data Flow

```
User Input
    │
    ▼
┌─────────────────┐
│  SwiftUI View   │ (AddWeightEntryView, etc.)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  DataManager    │ (Validation & CRUD)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   SwiftData     │ (Persistence)
│  ModelContext   │
## Code Layout

### Xcode App Project (current)

```text
Trimly/               # App target sources (iOS + macOS)
    Trimly.swift
    TrimlyApp.swift
    Models/
    Services/
    Views/
    Widget/

TrimlyTests/          # XCTest target
    DataManagerTests.swift
    TrimlyTests.swift
    WeightAnalyticsTests.swift
```
    │   ├── Unit Selection Page
    │   ├── Starting Weight Page
    │   ├── Goal Setting Page
    │   ├── Reminders Page
    │   └── EULA Page
    │
    └── MainTabView
        │
        ├── DashboardView
        │   ├── Today Weight Card
        │   ├── Mini Sparkline Card
        │   ├── Progress Summary Card
        │   ├── Consistency Score Card
        │   ├── Trend Summary Card
        │   └── Projection Card
        │
        ├── TimelineView
        │   └── List
        │       └── ForEach (Day Groups)
        │           ├── Section Header (Daily Aggregate)
        │           └── Entry Rows
        │
        ├── ChartsView
        │   ├── Range Picker
        │   ├── Chart
        │   │   ├── Weight Line
        │   │   ├── Moving Average Line
        │   │   ├── EMA Line
        │   │   └── Goal Line
        │   ├── Legend
        │   └── Statistics
        │
        └── SettingsView
            ├── Units Section
            ├── Goal Section
            ├── Aggregation Section
            ├── Reminders Section
            ├── Consistency Section
            ├── Data Section
            └── About Section
```

## Service Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    DataManager                          │
│                   (@MainActor)                          │
├─────────────────────────────────────────────────────────┤
│ Properties:                                             │
│  • modelContainer: ModelContainer                       │
│  • modelContext: ModelContext                           │
│  • settings: AppSettings                                │
├─────────────────────────────────────────────────────────┤
│ Weight Entry Methods:                                   │
│  • addWeightEntry(...)                                  │
│  • fetchAllEntries() -> [WeightEntry]                   │
│  • fetchEntriesForDate(_:) -> [WeightEntry]             │
│  • deleteEntry(_:)                                      │
│  • updateEntry(_:notes:)                                │
├─────────────────────────────────────────────────────────┤
│ Goal Methods:                                           │
│  • setGoal(...)                                         │
│  • fetchActiveGoal() -> Goal?                           │
│  • fetchGoalHistory() -> [Goal]                         │
│  • completeGoal(reason:)                                │
├─────────────────────────────────────────────────────────┤
│ Analytics Methods:                                      │
│  • getDailyWeights() -> [(Date, Double)]                │
│  • getCurrentWeight() -> Double?                        │
│  • getStartWeight() -> Double?                          │
│  • getConsistencyScore() -> Double?                     │
│  • getTrend() -> TrendDirection                         │
│  • getGoalProjection() -> Date?                         │
├─────────────────────────────────────────────────────────┤
│ Data Management:                                        │
│  • exportToCSV() -> String                              │
│  • deleteAllData()                                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                 WeightAnalytics                         │
│                  (Static Service)                        │
├─────────────────────────────────────────────────────────┤
│ Aggregation:                                            │
│  • aggregateByDay(entries:mode:)                        │
├─────────────────────────────────────────────────────────┤
│ Smoothing:                                              │
│  • calculateMovingAverage(dailyWeights:period:)         │
│  • calculateEMA(dailyWeights:period:)                   │
├─────────────────────────────────────────────────────────┤
│ Scoring:                                                │
│  • calculateConsistencyScore(entries:windowDays:)       │
├─────────────────────────────────────────────────────────┤
│ Trend Analysis:                                         │
│  • classifyTrend(dailyWeights:)                         │
│  • calculateLinearRegression(dailyWeights:)             │
├─────────────────────────────────────────────────────────┤
│ Projections:                                            │
│  • calculateGoalProjection(...)                         │
└─────────────────────────────────────────────────────────┘
```

## Model Relationships

```
┌──────────────────┐
│   WeightEntry    │
├──────────────────┤
│ id: UUID         │
│ timestamp: Date  │
│ normalizedDate   │
│ weightKg: Double │
│ displayUnit      │
│ source: Source   │
│ notes: String?   │
│ isHidden: Bool   │
└──────────────────┘
        │
        │ Multiple entries
        │ per normalized date
        ▼
  [Daily Aggregate]


┌──────────────────┐
│      Goal        │
├──────────────────┤
│ id: UUID         │
│ targetWeightKg   │
│ startDate        │
│ isActive: Bool   │
│ completedDate?   │
│ startingWeight?  │
└──────────────────┘
        │
        │ One active,
        │ many historical
        ▼
   [Goal History]


┌──────────────────┐
│   AppSettings    │
├──────────────────┤
│ preferredUnit    │
│ aggregationMode  │
│ chartMode        │
│ reminderTime?    │
│ healthKitEnabled │
│ ...              │
└──────────────────┘
        │
        │ Singleton
        │
        ▼
   [User Prefs]
```

## Technology Stack

```
┌─────────────────────────────────────────────┐
│              Application Layer              │
│                  SwiftUI                    │
├─────────────────────────────────────────────┤
│             Business Logic                  │
│         DataManager & Analytics             │
├─────────────────────────────────────────────┤
│              Data Layer                     │
│               SwiftData                     │
├─────────────────────────────────────────────┤
│              Storage Layer                  │
│      SQLite + iCloud (CloudKit)             │
└─────────────────────────────────────────────┘

Supporting Frameworks:
  • Foundation (Core utilities)
  • Swift Charts (Visualization)
  • HealthKit (Future - health data)
  • UserNotifications (Future - reminders)
  • WidgetKit (Future - widgets)
```

## Build & Test Flow

```
Source Code
    │
    ▼
Swift Compiler
    │
    ▼
Swift Package Manager
    │
    ├─────────────┬──────────────┐
    ▼             ▼              ▼
 Trimly.app   Tests Build    Documentation
    │             │
    │             ▼
    │        XCTest Runner
    │             │
    │             ▼
    │        Test Results
    │
    ▼
Xcode / Command Line
    │
    ├──────────┬──────────┐
    ▼          ▼          ▼
  iOS        macOS     Simulator
 Device       App
```

## Deployment Targets

```
iOS 17.0+
    │
    ├── iPhone (6.1" - 6.7")
    ├── iPhone (5.4" - 6.1")
    ├── iPad (10.2" - 12.9")
    └── iPad Mini (8.3")

macOS 14.0+
    │
    ├── MacBook (13" - 16")
    ├── iMac (24" - 27")
    └── Mac Studio / Pro
```

---

**Legend:**
- `┌─┐` : Container/Module
- `│ ▼` : Vertical flow
- `├─┤` : Horizontal connection
- `[  ]` : Conceptual grouping
- `• ` : List item
