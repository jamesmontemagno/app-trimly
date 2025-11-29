## Plan: Pro Version IAP Integration (StoreKit 2)

We will implement a "Pro" tier using StoreKit 2, utilizing the modern `ProductView` for the paywall and a local StoreKit configuration for testing.

### Steps
1. Create `TrimTally.storekit` configuration file defining the `trimtallypro` non-consumable product for local testing.
2. Create [Services/StoreManager.swift](Services/StoreManager.swift) to handle product fetching, entitlement verification (`Transaction.currentEntitlements`), and purchase updates.
3. Create [Views/PaywallView.swift](Views/PaywallView.swift) using `ProductView` to display the "Pro" upgrade with built-in purchase handling, wrapped in a sheet with marketing copy.
4. Update [TrimlyApp.swift](TrimlyApp.swift) to initialize `StoreManager` and inject it as an `.environmentObject`.
5. Modify [Views/SettingsView.swift](Views/SettingsView.swift) to show a "Get Pro" banner and a "Restore Purchases" button.
6. Update [Views/SettingsView.swift](Views/SettingsView.swift) to gate the "HealthKit" and "Export" features, presenting `PaywallView` as a sheet if the user is not Pro.

### Further Considerations
1. **StoreKit Testing**: You will need to enable the StoreKit configuration scheme in Xcode (Product > Scheme > Edit Scheme > Run > Options > StoreKit Configuration) after I create the file.
2. **Customization**: `ProductView` handles the button and price display automatically. We will add the "Why Upgrade?" text above it.
