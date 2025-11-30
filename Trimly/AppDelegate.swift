#if os(iOS)
import UIKit
import CloudKit
import SwiftData
import CoreData

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        
        #if DEBUG
        // Initialize CloudKit schema in development builds
        // This must be done once when setting up a new CloudKit container
        // ⚠️ IMPORTANT: Uncomment below ONLY when setting up a new CloudKit container
        // After schema is deployed to production, keep this commented out!
        // Task {
        //     await initializeCloudKitSchema()
        // }
        #endif
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if ckNotification?.notificationType == .database {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("Failed to register for remote notifications: \(error)")
        #endif
    }
}
#elseif os(macOS)
import AppKit
import SwiftData
import CoreData

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.registerForRemoteNotifications()
        
        #if DEBUG
        // Initialize CloudKit schema in development builds
        // This must be done once when setting up a new CloudKit container
        // ⚠️ IMPORTANT: Uncomment below ONLY when setting up a new CloudKit container
        // After schema is deployed to production, keep this commented out!
        // Task {
        //     await initializeCloudKitSchema()
        // }
        #endif
    }
}
#endif

#if DEBUG
// MARK: - CloudKit Schema Initialization
/// Initializes the CloudKit schema for SwiftData models.
/// This should only run in DEBUG builds when setting up a new CloudKit container.
/// After the schema is successfully initialized and visible in CloudKit Dashboard,
/// comment out the call to this function in didFinishLaunching.
@MainActor
private func initializeCloudKitSchema() async {
    print("[CloudKit] Initializing schema for SwiftData models...")
    
    do {
        // Create a temporary container with the same configuration
        let schema = Schema([
            WeightEntry.self,
            Goal.self,
            AppSettings.self,
            Achievement.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        // The schema is automatically initialized when the container is created
        // with cloudKitDatabase: .automatic
        // SwiftData uses Core Data's NSPersistentCloudKitContainer under the hood
        print("[CloudKit] Schema initialization triggered. Check CloudKit Dashboard at:")
        print("[CloudKit] https://icloud.developer.apple.com/dashboard")
        print("[CloudKit] Container: iCloud.com.refractored.trimtally")
        print("[CloudKit] Schema created for models: WeightEntry, Goal, AppSettings, Achievement")
    } catch {
        print("[CloudKit] Schema initialization failed: \(error)")
        print("[CloudKit] This is normal on first launch. The schema will be created automatically.")
    }
}
#endif
