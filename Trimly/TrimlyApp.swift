//
//  TrimlyApp.swift
//  Trimly
//
//  Created by James Montemagno on 11/27/25.
//

import SwiftUI
import SwiftData

@main
struct TrimlyApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, dataManager.modelContext)
                .environmentObject(dataManager)
        }
        .modelContainer(dataManager.modelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(dataManager)
        }
        #endif
    }
}
