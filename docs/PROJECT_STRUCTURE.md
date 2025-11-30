# TrimTally Project Structure

```
app-trimly/
│
├── .gitignore                         # Git ignore rules
├── LICENSE                            # Project license
├── README.md                          # Project overview and quick start
├── CONTRIBUTING.md                    # Contribution guidelines
├── docs/                              # Detailed project documentation
│   ├── BUILD_INSTRUCTIONS.md          # Build guidance
│   ├── DESIGN_DOCUMENT.md             # Design specifications
│   └── ...
│
├── TrimTally.xcodeproj/               # Shared iOS + macOS project
│
├── Trimly/                            # Main application target
│   │
│   ├── TrimlyApp.swift                # App entry point (@main)
│   ├── Trimly.swift                   # Shared app scene wiring
│   │
│   ├── Models/                        # SwiftData @Model types
│   │   ├── WeightEntry.swift
│   │   ├── Goal.swift
│   │   └── AppSettings.swift
│   │
│   ├── Services/                      # Business logic + integrations
│   │   ├── DataManager.swift          # Central data/service hub
│   │   ├── WeightAnalytics.swift      # Analytics utilities
│   │   ├── HealthKitService.swift     # Health import + sync
│   │   ├── NotificationService.swift  # Reminder scheduling
│   │   ├── CelebrationService.swift   # Celebration badge logic
│   │   └── PlateauDetectionService.swift # Plateau detection
│   │
│   ├── Views/                         # SwiftUI screens
│   │   ├── ContentView.swift          # Root navigation
│   │   ├── DashboardView.swift
│   │   ├── TimelineView.swift
│   │   ├── ChartsView.swift
│   │   ├── SettingsView.swift
│   │   ├── AddWeightEntryView.swift
│   │   ├── HealthKitView.swift
│   │   └── Components/                # Shared UI elements
│   │
│   ├── Localization/                  # L10n helpers + xcstrings
│   ├── Widget/                        # WidgetKit extension
│   ├── Assets.xcassets                # Shared asset catalog
│   ├── LaunchScreen.storyboard        # Launch UI
│   ├── Trimly.entitlements            # Debug entitlements
│   └── TrimlyRelease.entitlements     # Release entitlements
│
├── TrimlyTests/                       # Unit test target
│   ├── TrimlyTests.swift
│   ├── DataManagerTests.swift
│   └── WeightAnalyticsTests.swift
│
└── TrimlyUITests/                     # UI test target
    ├── TrimlyUITests.swift
    └── TrimlyUITestsLaunchTests.swift
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
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SQLite Store   │ (Local) + iCloud sync via CloudKit
└─────────────────┘
```

## Code Layout

### Targets & Directories

```text
Trimly/                      # Shared iOS + macOS target
├── TrimlyApp.swift          # App entry point
├── Trimly.swift             # Scene + environment wiring
├── Models/                  # SwiftData models
├── Services/                # Data + analytics + integrations
├── Views/                   # SwiftUI views + Components/
├── Localization/            # L10n.swift and xcstrings catalog
├── Widget/                  # WidgetKit extension
├── Assets.xcassets          # Shared assets
└── *.entitlements           # Debug/Release entitlements

TrimlyTests/                 # XCTest unit target
TrimlyUITests/               # UITest target
docs/                        # Architecture + build documentation
```

### Navigation Outline

- **OnboardingFlow**: Unit selection → Starting weight → Goal → Reminders → EULA.
- **ContentView**: Switches between onboarding and the authenticated experience.
- **MainTabView**: Hosts Dashboard, Timeline, Charts, and Settings tabs.
  - **DashboardView**: Today card, sparkline, metrics, consistency, trend, projection, celebrations.
  - **TimelineView**: Sectioned list grouped by normalized day, with entry rows + contextual notes.
  - **ChartsView**: Range picker, Swift Charts stack (weight, SMA, EMA, goal), analytics summary.
  - **SettingsView**: Units, aggregation, goals, HealthKit, reminders, data management, about pane.

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
│  • fetchEntries(for:) -> [WeightEntry]                  │
│  • deleteEntry(_:)                                      │
│  • updateEntry(_:notes:isHidden:)                       │
├─────────────────────────────────────────────────────────┤
│ Goal & Settings:                                        │
│  • setGoal(...)                                         │
│  • fetchActiveGoal() -> Goal?                           │
│  • fetchGoalHistory() -> [Goal]                         │
│  • completeGoal(reason:)                                │
│  • updateSettings(transform:)                           │
├─────────────────────────────────────────────────────────┤
│ Analytics Helpers:                                      │
│  • getDailyWeights(mode:) -> [(Date, Double)]           │
│  • getConsistencyScore(windowDays:) -> Double?          │
│  • getTrendSummary() -> TrendDirection                  │
│  • getGoalProjection() -> Date?                         │
├─────────────────────────────────────────────────────────┤
│ Integrations & Utilities:                               │
│  • importHealthData(range:)                             │
│  • enableBackgroundSync(_:)                             │
│  • refreshHealthSamples()                               │
│  • scheduleReminders()                                  │
│  • exportToCSV() -> String                              │
│  • deleteAllData()                                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                 WeightAnalytics                         │
│                  (Static Service)                       │
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

┌─────────────────────────────────────────────────────────┐
│                HealthKitService                         │
├─────────────────────────────────────────────────────────┤
│  • requestAuthorization()                               │
│  • fetchSampleCount(range:) -> Int                      │
│  • importSamples(range:)                                │
│  • startBackgroundDelivery()                            │
│  • handleNewSamples(_:)                                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              NotificationService                        │
├─────────────────────────────────────────────────────────┤
│  • requestAuthorizationIfNeeded()                       │
│  • scheduleReminder(hour:minute:type:)                  │
│  • cancelReminder(type:)                                │
│  • refreshScheduledReminders(settings:)                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│             CelebrationService                          │
├─────────────────────────────────────────────────────────┤
│  • recentWins(entries:) -> Celebration?                 │
│  • milestoneMessage(for:) -> String                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│         PlateauDetectionService                         │
├─────────────────────────────────────────────────────────┤
│  • detectPlateau(dailyWeights:) -> PlateauState         │
│  • recentSlopeInfo(dailyWeights:)                       │
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
│ appearance       │
│ decimalPrecision │
│ projectionMethod │
│ onboardingFlags  │
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
    • HealthKit (Import + sync)
    • UserNotifications (Adaptive reminders)
    • WidgetKit (TrimTally widgets)
    • CloudKit (SwiftData sync)
```

## Build & Test Flow

```
Source Code (Trimly target / Widget)
        │
        ▼
   Swift Compiler
        │
        ▼
   Xcode Build System / xcodebuild
        │
        ├─────────────┬──────────────┐
        ▼             ▼              ▼
  TrimTally.app   Widget Extension   XCTest Bundles
        │                              │
        │                              ▼
        │                          XCTest Runner (⌘U / xcodebuild test)
        │
        ▼
  Simulator / Device / macOS App
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
