//
//  DebugFlags.swift
//  TrimTally
//
//  Created by Trimly on 12/17/2025.
//

import Foundation

/// Global debug flags for controlling debug-only features in production builds.
/// Toggle these flags to show/hide debug features across the app.
struct DebugFlags {
	/// Set to `true` to show the "View Scheduled Notifications" debug button in Settings.
	/// Set to `false` to hide it.
	static let showPendingNotificationsDebug = false
	
	/// Set to `true` to enable sample data generation in Settings.
	/// Set to `false` to hide it.
	static let showSampleDataGeneration = false
}
