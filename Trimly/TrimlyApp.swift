//
//  TrimlyApp.swift
//  TrimTally
//
//  Created by James Montemagno on 11/27/25.
//

import SwiftUI
import SwiftData

@main
struct TrimlyApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var storeManager = StoreManager()
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, dataManager.modelContext)
                .environmentObject(dataManager)
                .environmentObject(dataManager.deviceSettings)
                .environmentObject(storeManager)
                .preferredColorScheme(colorScheme(for: dataManager.settings?.appearance))
        }
        .modelContainer(dataManager.modelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(dataManager)
                .environmentObject(dataManager.deviceSettings)
                .environmentObject(storeManager)
        }
        #endif
    }

    private func colorScheme(for appearance: AppAppearance?) -> ColorScheme? {
        switch appearance ?? .system {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
