//
//  ContentView.swift
//  TrimTally
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
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        celebrationService.dismissCelebration()
                    }
            }
        }
        .onAppear {
            achievementService.refresh(using: dataManager, isPro: storeManager.isPro)
            celebrationService.checkAllCelebrations(dataManager: dataManager)
        }
        .onChange(of: entryCount) { _, _ in
            achievementService.refresh(using: dataManager, isPro: storeManager.isPro)
            celebrationService.checkAllCelebrations(dataManager: dataManager)
        }
        .onChange(of: storeManager.isPro) { _, _ in
            achievementService.refresh(using: dataManager, isPro: storeManager.isPro)
        }
    }
    
    // MARK: - Helpers
    
    private var entryCount: Int {
        dataManager.fetchAllEntries().count
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager(inMemory: true))
        .environmentObject(StoreManager())
}
