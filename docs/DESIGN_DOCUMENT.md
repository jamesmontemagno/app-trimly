# Trimly Design Document

## Product Overview

Trimly is a modern weight tracking application for iOS and macOS that provides a supportive, mindful approach to weight management. The app emphasizes consistency, progress visualization, and gentle encouragement rather than judgment.

## Design Principles

1. **Supportive, not judgmental**: Language and UI elements encourage progress without shame
2. **Simplicity first**: Quick entry flow, clear metrics, minimal friction
3. **Data ownership**: Full export capability, transparent about data usage
4. **Flexibility**: Support various tracking patterns (daily, sporadic, multiple entries)
5. **Beautiful visualization**: Elegant charts that make data interpretation easy
6. **Privacy-focused**: Local-first storage, optional cloud sync, no third-party tracking

## User Personas

### Primary: Sarah - The Consistent Tracker
- Logs weight daily in the morning
- Motivated by seeing trends over time
- Wants to reach specific goal weight
- Uses reminders to build habit
- Values clean, simple interface

### Secondary: Mike - The Periodic Logger
- Logs weight 2-3 times per week
- Interested in general trends, not daily fluctuations
- Occasionally logs multiple times per day (morning/evening)
- Prefers minimal notifications
- Uses HealthKit with smart scale

### Tertiary: Alex - The Data Enthusiast
- Logs multiple times daily
- Wants detailed analytics and projections
- Exports data for external analysis
- Interested in smoothing algorithms and trend lines
- Uses analytical chart mode

## User Journeys

### First-Time User Flow

1. **Welcome**: Friendly introduction to Trimly
2. **Unit Selection**: Choose pounds or kilograms
3. **Starting Weight** (optional): Log initial measurement
4. **Goal Setting** (optional): Set target weight
5. **Reminders** (optional): Enable daily reminders
6. **EULA**: Accept terms and privacy policy
7. **Main App**: Arrives at dashboard, ready to use

### Daily Logging Flow

1. **Open App**: See today's dashboard
2. **Tap +**: Quick entry sheet appears
3. **Enter Weight**: Numeric input with unit display
4. **Optional**: Add date/time (defaults to now)
5. **Optional**: Add notes
6. **Save**: Entry recorded, sheet dismisses
7. **View Update**: Dashboard reflects new weight

### Progress Checking Flow

1. **Dashboard Tab**: Quick overview of current state
2. **Timeline Tab**: See all entries chronologically
3. **Charts Tab**: Visualize trends over time
4. **Settings Tab**: Review goal, export data

## Feature Specifications

### Version 1.0 Features

#### Multi-Entry Per Day
- **Requirement**: Allow unlimited entries per calendar day
- **Rationale**: Some users weigh multiple times (morning/evening)
- **Implementation**: Normalized date field for daily grouping
- **Aggregation**: User chooses "latest" or "average" for daily value

#### Dashboard
- **Today's Weight**: Large, prominent display
- **7-Day Sparkline**: Quick visual trend
- **Progress Metrics**:
  - Delta from starting weight
  - Delta to goal weight
  - Percentage progress
- **Consistency Score**: Badge showing logging consistency
- **Trend Summary**: "Gradual decrease", "Steady", etc.
- **Goal Projection** (conditional): Estimated date to reach goal

#### Timeline
- **Grouped by Day**: Collapsible daily sections
- **Daily Aggregate**: Header shows aggregated value
- **Entry Details**: Time, value, source, notes
- **Management**: Swipe to delete
- **Source Badges**: Visual indicator for HealthKit entries

#### Charts
- **Range Selection**: Week, Month, Quarter, Year
- **Weight Line**: Smooth interpolated line
- **Moving Average**: Optional 7-day SMA overlay
- **EMA**: Optional exponential smoothing overlay
- **Goal Line**: Horizontal target indicator
- **Display Modes**:
  - Minimalist: Clean, no grid/axes
  - Analytical: Full axes, grid, tooltips
- **Statistics**: Min, max, average, range for selected period

#### Goal Management
- **Single Active Goal**: One target weight at a time
- **Historical Goals**: Archive of past goals
- **Auto-Archive**: Setting new goal archives current
- **Completion Tracking**: Reason (achieved/changed/abandoned)
- **Starting Weight**: Captured when goal set

#### Analytics

##### Moving Average (SMA)
- Configurable period (3-30 days, default 7)
- Classic smoothing for trend visibility
- Displayed as dashed overlay

##### Exponential Moving Average (EMA)
- Configurable period (3-30 days, default 7)
- More responsive to recent changes
- Displayed as dotted overlay

##### Consistency Score
- Rolling window (7-90 days, default 30)
- Formula: `(days_with_entries / window_days) × 100%`
- Qualitative labels:
  - ≥85%: "Very consistent"
  - 70-84%: "Consistent"
  - 50-69%: "Moderate"
  - <50%: "Building consistency"
- Color coding: Green, blue, orange, red

##### Trend Classification
- **Downward**: Slope < -0.02 kg/day
- **Upward**: Slope > 0.02 kg/day
- **Stable**: -0.02 ≤ slope ≤ 0.02 kg/day
- Based on linear regression

##### Goal Projection
- Requirements:
  - Minimum 10 days of data
  - Trend direction matches goal
  - Slope magnitude ≥ 0.02 kg/day
  - Distance to goal ≥ 0.5 kg
- Volatility filtering: Exclude last 2 days if >5% jump
- Algorithm: Linear regression extrapolation
- Display: "Estimated goal date: [date]" with days remaining

#### Data Export
- Format: CSV
- Columns:
  - id, timestamp, normalizedDate
  - weight_kg, displayUnitAtEntry, weight_display_value
  - source, notes
  - createdAt, updatedAt
- Raw data only (no derived metrics)
- Share sheet integration

#### Settings
- **Units**:
  - Weight unit (kg/lb)
  - Decimal precision (1 or 2 places)
- **Aggregation**: Latest vs Average
- **Reminders**:
  - Enable/disable
  - Time selection
  - Adaptive suggestions (planned)
- **Consistency**: Window size
- **Data**: Export, delete all
- **About**: Version, privacy, terms

#### Onboarding
- 6-page flow
- All steps optional except EULA
- Remembers completion state
- Can't be re-triggered (settings-based)

### Future Features (Post-v1)

#### HealthKit Integration
- Historical import with date range selector
- Background passive sync
- Duplicate detection (tolerance-based)
- Auto-hide duplicates option
- Manual/HealthKit entry distinction

#### Reminders
- Local notifications
- Daily schedule
- Adaptive suggestions:
  - Track 3 consecutive dismissals
  - Analyze median logging time
  - Suggest time adjustment
- Optional second reminder
- Cancel if already logged

#### Micro Celebrations
- Milestone triggers:
  - First week streak
  - 10 entries logged
  - 25%, 50%, 75%, 100% to goal
  - 70%, 85% consistency
- Animation: Subtle confetti or glow
- Message: "Nice streak—7 days of consistency!"
- VoiceOver accessible

#### Widget
- **Small**: Current weight + delta
- **Medium** (future): Mini sparkline
- Tap action: Open quick entry
- Updates via WidgetKit timeline

#### Plateau Detection
- Detect 14+ days with < 0.5% change
- Subtle hint: "Weight stabilized—consider adjusting routine"
- Non-intrusive, dismissible

#### Manual Daily Override
- User can select "primary" entry for a day
- Overrides automatic latest/average
- Stored as metadata on entry

## Technical Architecture

### Data Layer

#### SwiftData Models
- **WeightEntry**: Individual measurements
- **Goal**: Weight targets
- **AppSettings**: User preferences

#### Storage
- SwiftData with SQLite backend
- iCloud sync via ModelConfiguration
- Automatic conflict resolution
- Optimized queries with FetchDescriptor

### Service Layer

#### DataManager
- Main Actor-bound
- Singleton pattern via environment
- Manages model context
- Provides high-level CRUD operations
- Caches settings for performance

#### WeightAnalytics
- Static utility functions
- Pure calculations (no state)
- Optimized for performance
- Comprehensive test coverage

### Presentation Layer

#### SwiftUI Views
- MVVM pattern
- Environment-injected dependencies
- Declarative state management
- Responsive to data changes
- Platform-adaptive (iOS/macOS)

### Sync & Integration

#### iCloud (SwiftData)
- Automatic via ModelConfiguration
- Merge policy: Client-side reconciliation
- Background upload/download
- Handles device-to-device conflicts

#### HealthKit (Future)
- Read-only access to HKQuantityType.bodyMass
- Background delivery for ongoing sync
- Duplicate detection algorithm
- Permission-gated

## UI/UX Specifications

### Typography
- **Large Title**: 34pt, Bold (Dashboard weight)
- **Title**: 28pt, Bold (Page headers)
- **Title 2**: 22pt, Bold (Section headers)
- **Title 3**: 20pt, Bold (Metric labels)
- **Body**: 17pt, Regular (Content)
- **Caption**: 12pt, Regular (Metadata)

### Color Palette
- **Primary Blue**: Weight line, buttons
- **Green**: Downward trend (if losing), goal achieved
- **Orange**: Moving average, upward trend
- **Purple**: EMA, projections
- **Red**: Alerts, delete actions
- **Secondary Gray**: Metadata, disabled states

### Spacing
- **Card Padding**: 16pt
- **Section Spacing**: 24pt
- **Element Spacing**: 12pt
- **Tight Spacing**: 8pt

### Animations
- **Entry Addition**: Slide in from bottom
- **Celebration**: Scale + opacity pulse
- **Chart Transition**: Smooth interpolation
- **Data Refresh**: Subtle fade

### Key Screens & Components (Visual Overview)

This section summarizes the most important new v1.1/v1.2 surfaces; see the app for exact visuals.

- **HealthKit Integration Screen**
  - Authorization status row (checkmark when enabled).
  - Historical import section with date range, sample count, and "Import Historical Data" button.
  - Background sync and "Auto-hide duplicates" toggles.

- **Reminders Screen**
  - Notification authorization status row.
  - Primary daily reminder time picker and optional secondary reminder.
  - "Smart time suggestions" area showing a suggested time based on logging patterns and an "Apply suggestion" action.

- **Dashboard Enhancements**
  - Celebration overlay: transient, centered card with icon and supportive message (e.g., "Halfway to your goal—keep it up!"), auto-dismissed after a short delay.
  - Plateau card: dismissible info card embedded in the dashboard, explaining that weight has stabilized over ~14 days with gentle guidance.

- **Widgets (iOS)**
  - Small widget: current weight, unit, and delta with arrow indicator.
  - Medium widget: current weight and delta on the left, trend label on the right (e.g., "Gradual decrease"), designed to match the in-app dashboard tone.

### Accessibility
- Dynamic Type support
- VoiceOver labels for all controls
- High contrast mode compatibility
- Reduce Motion support
- Keyboard navigation (macOS)

## Data Privacy & Security

### Principles
- **Local-first**: All data stored on device
- **Optional Cloud**: iCloud sync opt-in
- **No Third-Party**: No analytics, ads, or tracking
- **Transparent**: Clear privacy policy
- **User Control**: Full export and delete

### Compliance
- **GDPR**: Right to access, delete, export
- **CCPA**: Data portability and deletion
- **HealthKit**: Explicit permission required
- **App Store**: Standard EULA and privacy policy

### Data Handling
- **No Collection**: Trimly doesn't collect data
- **No Sharing**: Data never leaves user's control
- **No Analytics**: No crash reports or usage tracking
- **Encryption**: iCloud data encrypted in transit and at rest

## Performance Targets

### Responsiveness
- Cold launch: < 2 seconds
- Entry save: < 500ms
- Chart render: < 600ms
- Timeline scroll: 60 fps
- Dashboard update: < 200ms

### Scalability
- Support 14,600+ entries (8/day × 5 years)
- Chart with 365 points: < 1 second
- Search/filter 10,000 entries: < 500ms
- Export 5,000 entries: < 2 seconds

### Memory
- Idle: < 30 MB
- Active use: < 50 MB
- Chart rendering: < 70 MB
- Large dataset: < 100 MB

## Testing Strategy

### Unit Tests
- Analytics calculations (SMA, EMA, regression)
- Data manager operations
- Model logic and transformations
- Edge cases and boundary conditions

### Integration Tests
- SwiftData CRUD operations
- Multi-entry aggregation
- Goal lifecycle
- Export functionality

### UI Tests (Future)
- Onboarding flow
- Entry creation
- Navigation
- Settings changes

### Manual Testing
- Platform-specific behaviors (iOS vs macOS)
- iCloud sync across devices
- HealthKit integration
- Widget updates
- Notifications

## Localization (Future)

### Phase 1 Languages
- English (US/UK)
- Spanish
- French
- German
- Japanese

### Considerations
- Number formatting (1,234.5 vs 1.234,5)
- Date formats
- Unit preferences by region
- Right-to-left support (future: Arabic)

## Metrics & Success Criteria

### Engagement
- Daily active users
- Logging frequency
- Consistency score distribution
- Feature adoption (charts, export, etc.)

### Quality
- Crash-free sessions: > 99.5%
- App Store rating: > 4.5 stars
- Support tickets: < 1% of users

### Performance
- Launch time: < 2s for 90th percentile
- Frame rate: > 55 fps average
- Memory warnings: < 0.1% of sessions

## Open Questions (Answered)

1. **Daily aggregation default**: Latest entry ✓
2. **Weight precision**: 1 decimal place (configurable to 2) ✓
3. **EMA period**: 7 days (configurable 3-30) ✓
4. **Projection method**: Linear only initially ✓
5. **HealthKit duplicates**: Auto-hide with tolerance ✓
6. **Reminder adaptation**: 3 dismissals trigger ✓
7. **Widget data**: Weight + delta (simple) ✓

## Version Roadmap

### v1.0 (Current)
- Core tracking
- Dashboard, timeline, charts
- Goals and analytics
- Export and settings

### v1.1 (Next)
- HealthKit integration
- Reminders with adaptation
- Small widget

### v1.2
- Micro celebrations
- Plateau detection
- Medium widget

### v2.0 (Future)
- Apple Watch app
- Siri shortcuts
- Advanced analytics
- Social features (optional sharing)

---

**Last Updated**: November 19, 2025
**Version**: 1.0
**Status**: Implementation Complete
