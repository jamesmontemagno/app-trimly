//
//  TrimlyApp.swift
//  My Weight
//
//  Created by James Montemagno on 11/27/25.
//

import SwiftUI
import Combine
import SwiftData
import CoreData

struct AppRootView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var storeManager: StoreManager
    @StateObject private var healthKitService = HealthKitService.shared
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
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--show-all-chart-lines") {
                    dataManager.updateSettings {
                        $0.showMovingAverage = true
                        $0.showEMA = true
                    }
                }
                if ProcessInfo.processInfo.arguments.contains("--generate-sample-data") {
                    do {
                        try dataManager.generateSampleData(days: 365)
                    } catch {
                        dataManager.persistenceErrorMessage = error.localizedDescription
                    }
                }
                #endif
                NotificationService.shared.installResponseHandler()
                NotificationService.shared.configure(dataManager: dataManager)
                dataManager.refreshAfterExternalChanges()
                // Register HealthKit background observer on app launch if enabled
                #if os(iOS)
                healthKitService.registerBackgroundDeliveryIfEnabled(dataManager: dataManager)
                #endif
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    dataManager.refreshAfterExternalChanges()
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
                    .receive(on: DispatchQueue.main)
                    .compactMap { $0.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event }
                    .filter { $0.type == .import && $0.endDate != nil && $0.succeeded }
                    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            ) { _ in
                // Import completion only: reacting to our own saves/exports would loop.
                dataManager.refreshAfterExternalChanges()
            }
            .onReceive(dataManager.deviceSettings.remindersPublisher.debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)) { _ in
                Task {
                    await dataManager.refreshReminderSchedule()
                }
            }
            .alert(String(localized: L10n.Common.errorTitle), isPresented: Binding(
                get: { dataManager.persistenceErrorMessage != nil },
                set: { if !$0 { dataManager.persistenceErrorMessage = nil } }
            )) {
                Button(String(localized: L10n.Common.okButton), role: .cancel) {
                    dataManager.persistenceErrorMessage = nil
                }
            } message: {
                Text(dataManager.persistenceErrorMessage ?? "")
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
struct WeighApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var router = AppRouter.shared
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup(id: "main") {
            AppRootView(dataManager: dataManager)
                .environment(\.modelContext, dataManager.modelContext)
                .environmentObject(dataManager)
                .environmentObject(dataManager.deviceSettings)
                .environmentObject(router)
                .onOpenURL { router.handle($0) }
                #if os(macOS)
                .focusedSceneValue(\.isMyWeightMainWindow, true)
                #endif
        }
        .modelContainer(dataManager.modelContainer)
        #if os(macOS)
        .commands {
            QuickLogCommands(router: router)
        }
        #endif
        
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
