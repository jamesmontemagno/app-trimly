//
//  ContentView.swift
//  Trimly
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
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
            
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "list.bullet")
                }
            
            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager(inMemory: true))
}
