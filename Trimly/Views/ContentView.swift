//
//  ContentView.swift
//  Weigh
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Group {
            if dataManager.settings?.hasCompletedOnboarding == true {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            dataManager.refreshInitialCloudSyncState()
        }
        .task(id: dataManager.hasFinishedInitialCloudSync) {
            guard dataManager.hasFinishedInitialCloudSync == false else { return }
            while Task.isCancelled == false && dataManager.hasFinishedInitialCloudSync == false {
                dataManager.refreshInitialCloudSyncState()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var celebrationService = CelebrationService()
    @StateObject private var achievementService = AchievementService()
    
    enum Tab: Hashable {
        case dashboard
        case timeline
        case charts
        case achievements
        case settings
    }

    @State private var selectedTab: Tab = .dashboard
    @State private var showingQuickLog = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(onShowCharts: { selectedTab = .charts })
                .tabItem {
                    Label {
                        Text(L10n.Tabs.today)
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(Tab.dashboard)
		
            TimelineView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.timeline)
                    } icon: {
                        Image(systemName: "list.bullet")
                    }
                }
                .tag(Tab.timeline)
		
            ChartsView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.charts)
                    } icon: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }
                .tag(Tab.charts)

            AchievementsView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.achievements)
                    } icon: {
                        Image(systemName: "rosette")
                    }
                }
                .tag(Tab.achievements)
		
            SettingsView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.settings)
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
                .tag(Tab.settings)
        }
        .environmentObject(celebrationService)
        .environmentObject(achievementService)
        .overlay {
            if let celebration = celebrationService.currentCelebration {
                CelebrationOverlayView(celebration: celebration)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .onTapGesture {
                        celebrationService.dismissCelebration()
                    }
            }
        }
        .sheet(isPresented: $showingQuickLog) {
            AddWeightEntryView()
                .environmentObject(dataManager)
                .environmentObject(dataManager.deviceSettings)
                .environmentObject(storeManager)
                .environmentObject(celebrationService)
                .environmentObject(achievementService)
        }
        .onAppear {
            achievementService.refresh(using: dataManager, isPro: storeManager.isPro, celebrateUnlocks: false)
            presentPendingQuickLog()
        }
        .onChange(of: dataManager.dataRevision) { _, _ in
            achievementService.refresh(
                using: dataManager, isPro: storeManager.isPro,
                celebrateUnlocks: dataManager.lastChangeAllowsCelebration
            )
        }
        .onChange(of: dataManager.celebrationRevision) { _, _ in
            celebrationService.checkAllCelebrations(dataManager: dataManager)
        }
        .onChange(of: storeManager.isPro) { _, _ in
            achievementService.refresh(using: dataManager, isPro: storeManager.isPro, celebrateUnlocks: false)
        }
        .onChange(of: router.hasPendingQuickLog) { _, _ in presentPendingQuickLog() }
        .onChange(of: scenePhase) { _, _ in presentPendingQuickLog() }
    }
    
    // MARK: - Helpers
    
    private func presentPendingQuickLog() {
        guard router.consumeQuickLog(isReady: scenePhase == .active && dataManager.settings?.hasCompletedOnboarding == true) else { return }
        showingQuickLog = true
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager(inMemory: true))
        .environmentObject(StoreManager())
        .environmentObject(AppRouter())
}
