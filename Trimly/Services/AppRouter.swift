import Foundation
import Combine
#if os(macOS)
import SwiftUI
#endif

/// Buffers external navigation until an active, onboarded window can present it.
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published private(set) var hasPendingQuickLog = false

    func requestQuickLog() {
        hasPendingQuickLog = true
    }

    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard QuickLogLink.matches(url) else { return false }
        requestQuickLog()
        return true
    }

    @discardableResult
    func consumeQuickLog(isReady: Bool) -> Bool {
        guard isReady, hasPendingQuickLog else { return false }
        hasPendingQuickLog = false
        return true
    }
}

#if os(macOS)
private struct MainWindowKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var isMyWeightMainWindow: Bool? {
        get { self[MainWindowKey.self] }
        set { self[MainWindowKey.self] = newValue }
    }
}

struct QuickLogCommands: Commands {
    @ObservedObject var router: AppRouter
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.isMyWeightMainWindow) private var isMainWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(String(localized: L10n.PlatformFeatures.quickLogTitle)) {
                router.requestQuickLog()
                if isMainWindow != true {
                    openWindow(id: "main")
                }
            }
            .keyboardShortcut("n", modifiers: .command)
            .accessibilityLabel(String(localized: L10n.PlatformFeatures.quickLogTitle))
            .accessibilityHint(String(localized: L10n.PlatformFeatures.quickLogDescription))
        }
    }
}
#endif
