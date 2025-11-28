# Build Instructions for Trimly

## Prerequisites

Before building Trimly, ensure you have:

- **macOS 14.0 or later** (Sonoma or newer)
- **Xcode 15.0 or later**
- Active Apple Developer account (for device deployment)

## Quick Start

### Option 1: Open in Xcode (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/jamesmontemagno/app-trimly.git
   cd app-trimly
   ```

2. Double-click `Package.swift` in Finder, or run:
   ```bash
   open Package.swift
   ```

3. Wait for Xcode to resolve Swift packages (automatic)

4. Select your target:
   - **iOS**: Choose an iOS simulator or connected device
   - **macOS**: Choose "My Mac"

5. Build and run: Press `⌘R`

### Option 2: Command Line Build (macOS only)

```bash
# Clone repository
git clone https://github.com/jamesmontemagno/app-trimly.git
cd app-trimly

# Build
swift build -c release

# Run tests
swift test
```

**Note**: Command line builds work on macOS only, as SwiftUI and SwiftData require Apple platforms.

## Project Structure

```
app-trimly/
├── Package.swift              # Swift Package Manager manifest
├── Sources/
│   └── Trimly/
│       ├── Models/            # SwiftData models
│       ├── Services/          # Business logic
│       ├── Views/             # SwiftUI views
│       └── TrimlyApp.swift    # App entry point
└── Tests/
    └── TrimlyTests/           # Unit tests
```

## Running on Different Platforms

### iOS

1. Open `Package.swift` in Xcode
2. Select a target from the scheme selector:
   - iOS Simulator (iPhone 15 Pro recommended)
   - Physical iOS device (requires provisioning)
3. Press `⌘R` to build and run

### macOS

1. Open `Package.swift` in Xcode
2. Select "My Mac" from the scheme selector
3. Press `⌘R` to build and run

## Running Tests

### In Xcode
- Press `⌘U` to run all tests
- Or use Product → Test from the menu

### Command Line
```bash
swift test
```

## Common Issues

### "No such module SwiftData"
- **Cause**: Trying to build on Linux or non-Apple platform
- **Solution**: Use macOS with Xcode

### "Cannot find 'Model' in scope"
- **Cause**: Xcode version too old
- **Solution**: Update to Xcode 15.0 or later

### "Unable to resolve package dependencies"
- **Cause**: Network issues or package cache corruption
- **Solution**: 
  ```bash
  rm -rf ~/Library/Developer/Xcode/DerivedData
  ```
  Then reopen project in Xcode

### Signing Issues (iOS Device)
- **Cause**: Missing or invalid provisioning profile
- **Solution**: 
  1. Go to Project Settings → Signing & Capabilities
  2. Select your team
  3. Enable "Automatically manage signing"

## Performance Optimization

For release builds with optimizations:

```bash
swift build -c release
```

In Xcode:
1. Edit Scheme (⌘<)
2. Select "Run"
3. Change Build Configuration to "Release"

## Debugging

### Enable Verbose Logging

Add to your scheme's environment variables:
- `SQLITE_ENABLE_LOGGING` = `1` (for SwiftData/SQLite logging)

### Profiling

Use Instruments for performance analysis:
1. Product → Profile (⌘I)
2. Select instrument (Time Profiler, Allocations, etc.)

## Code Signing

For distribution:

1. **Developer ID Application** (for macOS outside App Store)
2. **iOS Distribution** (for TestFlight/App Store)

Configure in Xcode:
- Target → Signing & Capabilities
- Select appropriate profile

## CI/CD

For automated builds (GitHub Actions, etc.):

```yaml
- name: Build
  run: |
    xcodebuild -scheme Trimly \
               -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
               clean build
```

## Additional Resources

- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)

## Support

For build issues:
1. Check existing GitHub Issues
2. Review CONTRIBUTING.md
3. Open a new issue with:
   - macOS version
   - Xcode version
   - Error messages
   - Steps to reproduce
