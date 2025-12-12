# Building Swift iOS and Mac Apps with VS Code, GitHub Copilot, and Cloud Agents

Hey friends! James here. I've been getting a lot of questions lately about my development setup for building iOS and Mac apps—specifically how I've been using VS Code instead of Xcode, and how GitHub Copilot and its new Cloud Agent features have completely transformed my workflow. So I wanted to share my experience building TrimTally, a weight tracking app for iOS and macOS, using this modern setup.

## Why VS Code for Swift?

Look, I know what you're thinking: "James, are you crazy? Swift development without Xcode?" But hear me out. While Xcode is still necessary for certain tasks (you can't escape it entirely), VS Code has become my daily driver for actual coding, and the productivity gains have been remarkable.

The Swift extension for VS Code has matured significantly, giving you proper IntelliSense, code navigation, and debugging capabilities. Couple that with GitHub Copilot, and you've got a development environment that feels like having a senior Swift developer pair programming with you 24/7.

## The MCP Servers: Your Secret Weapons

One of the game-changers in my workflow has been setting up Model Context Protocol (MCP) servers. These are like specialized assistants that give Copilot superpowers for specific tasks. In my `.vscode/mcp.json`, I've configured two essential servers:

### XcodeBuildMCP

This server bridges the gap between VS Code and Xcode's build system. It lets me:
- Run builds directly from VS Code
- Execute tests on simulators
- Get build status and errors without switching contexts
- Manage multiple simulator targets

Here's my configuration:

```json
{
  "servers": {
    "XcodeBuildMCP": {
      "command": "npx",
      "args": ["-y", "xcodebuildmcp@latest"],
      "type": "stdio"
    }
  }
}
```

The beauty of this setup is that I can stay in VS Code while still leveraging Xcode's powerful build system. No more context switching between IDEs!

### Apple Docs MCP

The second MCP server I use is the Apple Docs server. This one is brilliant—it gives Copilot instant access to Apple's official documentation, so when you're working with SwiftUI, SwiftData, HealthKit, or any Apple framework, Copilot can pull in accurate, up-to-date API information.

```json
{
  "apple-docs": {
    "command": "npx",
    "args": ["-y", "@kimsungwhee/apple-docs-mcp"],
    "type": "stdio"
  }
}
```

This means when I'm implementing HealthKit integration or working with Swift Charts, Copilot knows the actual Apple APIs and can suggest code that follows best practices.

## The Extensions That Make It Work

My VS Code setup relies on two critical extensions:

### 1. Swift Extension

The official Swift extension provides language support, but what makes it powerful is the integration with SourceKit-LSP (Apple's language server). This gives you:
- Real-time syntax checking
- Code completion
- Symbol navigation (jump to definition, find references)
- Automatic imports
- Refactoring support

### 2. LLDB DAP (Debug Adapter Protocol)

Debugging Swift in VS Code is possible thanks to the LLDB DAP extension. My `launch.json` configuration looks like this:

```json
{
  "configurations": [
    {
      "type": "swift",
      "request": "launch",
      "name": "Debug TrimlyApp",
      "target": "TrimlyApp",
      "configuration": "debug",
      "preLaunchTask": "swift: Build Debug TrimlyApp"
    }
  ]
}
```

This setup gives me:
- Breakpoint debugging in VS Code
- Variable inspection
- Step through execution
- Console output
- All without leaving my editor

## GitHub Copilot Cloud Agent: The AI Pair Programmer

Now, here's where things get really interesting. GitHub Copilot's Cloud Agent feature is like having an AI engineer on your team who can actually make commits, open PRs, and implement entire features.

### Real Examples from TrimTally

Let me show you some actual PRs that Copilot Cloud Agent created for my TrimTally app:

#### PR #20: Complete Translation Support
I asked Copilot to "update all documentation and add Spanish and French translations for all strings." The agent:
- Scanned all 458 strings in the app
- Added complete Spanish and French translations
- Updated all documentation to reflect v1.2 status
- Fixed the CI workflow
- Created a comprehensive PR with detailed notes

All I had to do was review and merge. That would have taken me hours—Copilot did it in minutes.

#### PR #21: Interactive Chart Features
I wanted tap-to-toggle dots on the weight chart. I described the interaction pattern I wanted, and Copilot:
- Implemented progressive disclosure (tap to show dots, tap again to select)
- Added proper state management
- Included smooth animations
- Followed the existing `@ChartContentBuilder` pattern in the codebase
- Wrote it all in Swift 6 with modern concurrency

#### PR #19: Goal-Aware UI Components
For the progress summary card, I mentioned needing better stats and support for both weight loss and gain goals. Copilot:
- Restructured the layout for better visual hierarchy
- Added check-in counting with proper FetchDescriptor queries
- Implemented direction-aware color coding
- Localized all new strings in three languages
- Maintained consistency with the existing design system

#### PR #15: iCloud Sync Settings
This one was complex—adding a user-configurable iCloud sync setting with proper privacy messaging. Copilot:
- Created a new DeviceSettingsStore with proper persistence
- Modified DataManager to respect the setting
- Added an onboarding screen with privacy info
- Updated Settings with proper restart handling
- Wrote comprehensive tests
- Used Apple's official CloudKit terminology

### How I Work with Cloud Agent

My typical workflow looks like this:

1. **Describe the Feature**: I write a clear description of what I want—just like I would explain it to a teammate.

2. **Let It Plan**: Copilot analyzes the codebase, understands the architecture, and creates a plan.

3. **Watch It Work**: The agent makes targeted changes, following existing patterns and conventions.

4. **Review and Iterate**: I review the PR, provide feedback if needed, and Copilot can make adjustments.

5. **Merge**: Once I'm happy, I merge the PR.

The key is that Copilot understands the project structure, follows Swift conventions, respects the architecture patterns (like using DataManager for all data operations), and even writes appropriate tests.

## The CI/CD Pipeline

My GitHub Actions workflow is straightforward but effective. In `.github/workflows/macos-tests.yml`:

```yaml
name: macOS Unit Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  tests-macos:
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Select Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '26.0'
      
      - name: Build iOS app
        run: xcodebuild -scheme TrimTally -destination "platform=iOS Simulator,name=iPhone 17" build
```

This runs on every push and PR, ensuring that:
- The code builds successfully
- Tests pass on the target platforms
- Nothing breaks when merging changes

When Copilot opens a PR, the CI automatically validates the changes. If something breaks, I can either ask Copilot to fix it or handle it myself.

## The TrimTally Tech Stack

For context, TrimTally is built with:
- **Swift 6** with strict concurrency checking
- **SwiftUI** for all UI (iOS and macOS)
- **SwiftData** for persistence with iCloud sync
- **HealthKit** for importing and syncing weight data
- **WidgetKit** for home screen widgets
- **Swift Charts** for beautiful visualizations
- **UserNotifications** for adaptive reminders

The app supports:
- Multi-entry per day logging
- Comprehensive analytics (SMA, EMA, linear regression)
- Goal tracking with intelligent projections
- Consistency scoring
- Plateau detection
- Micro celebrations
- Full localization (English, Spanish, French)

## The Process Flow

Here's how a typical feature implementation flows:

1. **Open Issue or Chat**: I describe the feature in GitHub Issues or directly to Copilot.

2. **Copilot Analyzes**: The Cloud Agent:
   - Scans the repository structure
   - Understands existing patterns (DataManager, MVVM, service layer)
   - Reviews relevant files (models, views, services)
   - Checks `.github/copilot-instructions.md` for project conventions

3. **Creates PR**: Copilot:
   - Makes minimal, targeted changes
   - Follows existing code style
   - Adds necessary localizations
   - Updates documentation
   - Writes tests when appropriate
   - Commits with clear messages

4. **CI Validation**: GitHub Actions runs:
   - Builds the project
   - Runs unit tests
   - Reports any failures

5. **Review**: I review the changes, and if there are issues, I can:
   - Ask Copilot to fix them in comments
   - Make small tweaks myself
   - Request specific changes

6. **Merge**: Once satisfied, I merge the PR.

## Tips for Success

Based on my experience with TrimTally, here are my top tips:

### 1. Document Your Architecture
Create a `.github/copilot-instructions.md` that explains:
- Project structure
- Key conventions (like "all data operations go through DataManager")
- Code style preferences
- Common patterns

This helps Copilot understand your codebase and make changes that fit naturally.

### 2. Be Specific in Prompts
Don't just say "fix the chart." Instead: "On the main chart, let users tap to show dots for each day, with smooth animations. First tap shows dots, second tap selects the nearest point."

### 3. Review Carefully
Copilot is incredibly good, but it's not perfect. Always review:
- Logic correctness
- Edge cases
- Security implications
- Performance considerations

### 4. Leverage CI
Let your CI catch issues. If Copilot's PR breaks the build, the CI will catch it before you merge.

### 5. Use MCP Servers
The MCP servers elevate Copilot from "helpful" to "indispensable." The Apple Docs server especially makes SwiftUI development much smoother.

### 6. Keep Iterations Small
Instead of asking for a massive feature all at once, break it into smaller PRs. This makes review easier and reduces the chance of conflicts or bugs.

## The Developer Experience

I'll be honest: this setup has changed how I build apps. The combination of:
- VS Code's speed and extensibility
- Copilot's code suggestions and completion
- Cloud Agent's ability to implement features
- MCP servers providing specialized knowledge
- LLDB integration for debugging
- Continuous integration catching issues

...creates a development experience that feels futuristic. I spend less time fighting tools and more time thinking about product and user experience.

## Real-World Impact

TrimTally went from concept to a feature-complete v1.2 app in about three weeks. It has:
- 14 major features implemented
- ~1,800 lines of service layer code
- Comprehensive analytics
- Full internationalization
- Widget support
- HealthKit integration
- Adaptive reminders
- All with proper tests

And Copilot directly implemented or assisted with nearly every feature. PRs like #19, #20, #21, #22, and #23 were all primarily Copilot's work, with me providing direction and review.

## What's Next?

I'm continuing to refine this workflow. Some areas I'm exploring:
- Custom MCP servers for project-specific tasks
- Better integration with TestFlight distribution
- Automated UI testing in the CI pipeline
- More sophisticated code review automation

## Wrapping Up

Look, I get it—this might sound too good to be true. But I'm shipping real code to real users using this setup. TrimTally is available at [trimtally.app](http://trimtally.app/), and you can see all the PRs, commits, and code at [github.com/jamesmontemagno/app-trimly](https://github.com/jamesmontemagno/app-trimly).

The future of development isn't about AI replacing developers—it's about AI amplifying what we can build. With GitHub Copilot Cloud Agent, MCP servers, and a solid VS Code setup, I'm building better apps faster than ever before.

If you're working on Swift projects, I encourage you to try this workflow. Start small—set up the Swift extension and LLDB DAP for debugging. Then add Copilot. Then try the Cloud Agent on a small feature. You might be surprised at how much it changes your development experience.

Happy coding!

— James

---

*P.S. If you want to see the actual code and PRs I referenced, check out the TrimTally repository. All the GitHub Copilot PRs are right there with full commit history. It's pretty wild to see how much an AI can actually build when given proper context and direction.*

*P.P.S. TrimTally is open source under MIT license, so feel free to dig into the code, see how the SwiftData models are structured, check out the analytics implementations, or learn from the HealthKit integration. It's all there!*
