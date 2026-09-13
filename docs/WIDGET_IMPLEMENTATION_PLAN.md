# Widget integration

The widget extension is now part of `TrimTally.xcodeproj`. This replaces the earlier proposal to give the extension its own CloudKit-backed model container.

## Architecture

- `Trimly/Widget/TrimlyWidget.swift` is the extension entry point and renders small/medium widgets plus iOS circular, rectangular, and inline accessory widgets.
- `Trimly/Widget/WidgetSnapshotWriter.swift` belongs only to the app. It derives the latest visible measurement and recent daily aggregates using the existing DataManager and WeightAnalytics APIs.
- `Trimly/Widget/Shared/WidgetSnapshot.swift` defines a versioned, Codable display snapshot and its file store. It has no SwiftData, HealthKit, or app-model dependency.
- The app and extension share `group.com.refractored.trimtally`. The snapshot is stored as `weight-widget-snapshot.json` in that App Group, excluded from backups.
- The widget never opens the CloudKit store. No persisted model, relationship, property, or stored enum changes are required.

## Refresh and privacy

Successful entry, goal, and settings changes refresh the snapshot. Presentation preferences, app activation, and completed CloudKit imports refresh it too. Deleting all data writes an empty snapshot; enabling weight privacy writes a snapshot without weight history.

The app requests `WidgetCenter.reloadTimelines(ofKind:)`. WidgetKit controls the actual refresh budget, so updates are not guaranteed to appear immediately. Timeline entries mark older cached measurements as stale, and missing/invalid caches display an empty state rather than sample weights.

Widget views are privacy-sensitive and replace both visible and VoiceOver content when redacted. The privacy preference is device-local; it does not lock the app or remove stored measurements.

## Quick logging

Tapping a widget opens the same buffered quick-log route as reminder actions and the Shortcuts action. The app waits for an active window and completed onboarding before presenting the entry form. No weight is saved automatically.

## Signing and target membership

The project embeds `TrimTallyWidget` and keeps its `@main` source out of the app's synchronized source group. Shared value types are compiled into both targets; the snapshot writer is app-only.

In Xcode, configure an Apple development team and provisioning for:

- The existing app identifier.
- `com.refractored.trimtally.widget`.
- The App Group `group.com.refractored.trimtally` on both targets.

The extension requires App Groups, not its own CloudKit entitlement. Keep app and extension version/build numbers aligned when releasing.

## Development

```bash
xcodebuild -scheme TrimTally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -scheme TrimTally \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:TrimTallyTests/WidgetSnapshotTests \
  -only-testing:TrimTallyTests/PlatformRoutingTests test
```

Native builds and runtime widget inspection require macOS/Xcode. Exercise new entries, edits, hiding, deletion, unit changes, CloudKit imports, stale caches, privacy/VoiceOver, cold-launch links, and links received during onboarding before release.
