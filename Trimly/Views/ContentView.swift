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
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.today)
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
            
            TimelineView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.timeline)
                    } icon: {
                        Image(systemName: "list.bullet")
                    }
                }
            
            ChartsView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.charts)
                    } icon: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }

            AchievementsView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.achievements)
                    } icon: {
                        Image(systemName: "rosette")
                    }
                }
            
            SettingsView()
                .tabItem {
                    Label {
                        Text(L10n.Tabs.settings)
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager(inMemory: true))
}
