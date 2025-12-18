//
//  TrimlyApp.swift
//  TrimTally
//
//  Created by James Montemagno on 11/27/25.
//

import SwiftUI
import Combine
import SwiftData

struct AppRootView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var storeManager: StoreManager
    @StateObject private var healthKitService = HealthKitService()
    @Environment(\.scenePhase) private var scenePhase
    
    init(dataManager: DataManager) {
        // Initialize StoreManager with deviceSettings from DataManager
        _storeManager = StateObject(wrappedValue: StoreManager(deviceSettings: dataManager.deviceSettings))
    }
    
    var body: some View {
        ContentView()
            .environmentObject(storeManager)
            .preferredColorScheme(colorScheme(for: dataManager.settings?.appearance))
            .task {
                await dataManager.refreshReminderSchedule()
                // Register HealthKit background observer on app launch if enabled
                #if os(iOS)
                healthKitService.registerBackgroundDeliveryIfEnabled(dataManager: dataManager)
                #endif
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        await dataManager.refreshReminderSchedule()
                    }
                }
            }
            .onReceive(dataManager.deviceSettings.remindersPublisher.debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)) { _ in
                Task {
                    await dataManager.refreshReminderSchedule()
                }
            }
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

@main
struct TrimlyApp: App {
    @StateObject private var dataManager = DataManager()
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            AppRootView(dataManager: dataManager)
                .environment(\.modelContext, dataManager.modelContext)
                .environmentObject(dataManager)
                .environmentObject(dataManager.deviceSettings)
        }
        .modelContainer(dataManager.modelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(dataManager)
                .environmentObject(dataManager.deviceSettings)
                .environmentObject(StoreManager(deviceSettings: dataManager.deviceSettings))
        }
        #endif
    }
}
