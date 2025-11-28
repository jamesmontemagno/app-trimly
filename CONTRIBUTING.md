# Contributing to TrimTally

Thank you for your interest in contributing to TrTrimTallyimly!

## Development Environment

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

**Note**: TrimTally uses Apple-platform specific frameworks (SwiftUI, SwiftData) and cannot be built on Linux. Development and building must be done on macOS with Xcode.

## Building the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/jamesmontemagno/app-trimly.git
   cd app-trimly
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```
   
   Or simply double-click `Package.swift` in Finder.

3. Select your target platform (iOS or macOS) from the scheme selector

4. Build the project: `⌘B`

5. Run the app: `⌘R`

## Running Tests

In Xcode:
- Press `⌘U` to run all tests

Or from the command line on macOS:
```bash
swift test
```

## Project Structure

```
app-trimly/
├── Sources/
│   └── Trimly/
│       ├── Models/          # Data models (SwiftData)
│       ├── Services/        # Business logic & analytics
│       ├── Views/           # SwiftUI views
│       └── TrimlyApp.swift  # App entry point
├── Tests/
│   └── TrimlyTests/         # Unit tests
├── Package.swift            # Swift Package Manager manifest
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
- Trimly version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## Questions?

Feel free to open an issue for any questions about contributing.

Thank you for contributing to Trimly! 🎉
