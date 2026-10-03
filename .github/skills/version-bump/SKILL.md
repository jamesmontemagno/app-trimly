---
name: version-bump
description: Bump and synchronize the My Weight iOS and macOS app version across Xcode targets, the public version constant, and current-version documentation. Use when asked to bump, update, or prepare the app version for a release.
license: MIT
---

# My Weight Version Bumping

Use this workflow for version changes in the My Weight app. Treat the Xcode app target's `MARKETING_VERSION` as the canonical user-facing app version, and keep all app-related surfaces consistent without changing unrelated version fields.

## Version selection

- Read the current `MARKETING_VERSION` values in `TrimTally.xcodeproj/project.pbxproj` before choosing a new version.
- When asked for the "next 1.x version" or next minor version, increment the minor component and keep the major at `1` (for example, `1.2` becomes `1.3`).
- When the user specifies a target version, use it exactly after checking that it is newer than the current version.
- If the requested phrase does not identify whether to increment major, minor, or patch, ask before editing.
- Keep the Xcode marketing version's existing component format. Keep `MyWeight.version` in its existing three-component format, synchronized to the same release (for example, marketing `1.3` maps to `1.3.0`).
- Do not increment `CURRENT_PROJECT_VERSION` (the build number) unless the user asks for a build-number change or repository release instructions require it.

## Files to synchronize

1. Update every app, widget, unit-test, and UI-test `MARKETING_VERSION` entry in `TrimTally.xcodeproj/project.pbxproj` to the selected release version.
2. Update `Trimly/Trimly.swift`'s `MyWeight.version` to the same release using three components.
3. Update the current-version labels in `README.md` and `docs/PROJECT_STATUS.md`.
4. If the change includes a user-visible feature, update the current-version feature list in `README.md` with a concise entry.
5. Keep historical release notes and documentation (for example, `docs/FEATURE_IMPLEMENTATION_V1.2.md`) unchanged unless the user explicitly asks to revise them.

Do not change dependency versions, website package versions, asset-catalog versions, `WidgetSnapshot.currentVersion`, project archive/object versions, or other unrelated version-like values.

## Workflow

1. Check `git status --short` and preserve all existing edits.
2. Locate and compare all `MARKETING_VERSION` settings plus `MyWeight.version` and current-version documentation before editing.
3. Apply only the synchronized app-version changes and directly related current-version documentation updates.
4. Search again for stale current app-version values. Ignore historical versions and unrelated package/schema versions.
5. Run `git diff --check`.
6. Build the app with `xcodebuild -scheme TrimTally -destination 'platform=macOS,arch=arm64' build`. If the version change accompanies code changes, also run the smallest relevant test suite.

Report the resulting marketing version and build/test outcome. Do not commit unless requested.
