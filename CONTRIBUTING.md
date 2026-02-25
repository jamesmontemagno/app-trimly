# Contributing to Weigh

Thank you for your interest in contributing to Weigh!

## Development Environment

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

**Note**: Weigh uses Apple-platform specific frameworks (SwiftUI, SwiftData) and cannot be built on Linux. Development and building must be done on macOS with Xcode.

## Building the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/jamesmontemagno/app-trimly.git
   cd app-trimly
   ```

2. Open in Xcode:
   ```bash
   open Weigh.xcodeproj
   ```
   
   Or simply double-click `Weigh.xcodeproj` in Finder.

3. Select your target platform (iOS or macOS) from the scheme selector

4. Build the project: `⌘B`

5. Run the app: `⌘R`

## Running Tests

In Xcode:
- Press `⌘U` to run all tests

Or from the command line on macOS:
```bash
xcodebuild -scheme Weigh -destination 'platform=macOS,arch=arm64' test
```

## Project Structure

```
app-trimly/
├── Weigh.xcodeproj/         # Xcode project
├── Trimly/
│   ├── Models/                  # Data models (SwiftData)
│   ├── Services/                # Business logic & analytics
│   ├── Views/                   # SwiftUI views
│   ├── Localization/            # Translations (xcstrings)
│   ├── Widget/                  # WidgetKit extension
│   └── TrimlyApp.swift          # App entry point
├── TrimlyTests/                 # Unit tests
├── TrimlyUITests/               # UI tests
├── docs/                        # Documentation
└── README.md
```

## Code Style

- Use SwiftUI best practices
- Follow Swift API Design Guidelines
- Keep views modular and reusable
- Use descriptive variable and function names
- Add comments for complex logic
- Maintain separation of concerns (Models, Views, Services)

## Testing Guidelines

- Write tests for all business logic
- Test analytics calculations thoroughly
- Use in-memory storage for tests
- Ensure tests are isolated and can run independently

## Localization

Weigh supports multiple languages using String Catalogs (.xcstrings):

- All user-facing strings must use `NSLocalizedString` or the `L10n` helper
- Never hard-code strings in views
- Add new strings to `Trimly/Localization/Localizable.xcstrings`
- Provide translations for English, Spanish, and French
- Use descriptive keys following the pattern: `section.subsection.string`
- Test the app in different languages using Xcode's scheme settings

### Supported Languages

- English (primary)
- Spanish (Español)
- French (Français)

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write or update tests as needed
5. Ensure all tests pass (`⌘U` in Xcode)
6. Commit your changes with clear messages
7. Push to your fork
8. Open a Pull Request

## Coding Conventions

### SwiftUI Views

```swift
struct MyView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSheet = false
    
    var body: some View {
        // View implementation
    }
    
    // MARK: - Private Views
    
    private var subView: some View {
        // Subview implementation
    }
}
```

### Data Models

```swift
@Model
final class MyModel {
    var id: UUID
    var createdAt: Date
    
    init(id: UUID = UUID(), createdAt: Date = Date()) {
        self.id = id
        self.createdAt = createdAt
    }
}
```

## Feature Requests

Please open an issue to discuss new features before starting work on them.

## Bug Reports

When reporting bugs, please include:
- iOS/macOS version
- Weigh version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## Questions?

Feel free to open an issue for any questions about contributing.

Thank you for contributing to Weigh! 🎉
