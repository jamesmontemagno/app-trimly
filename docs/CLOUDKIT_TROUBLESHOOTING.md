# CloudKit Sync Troubleshooting Guide

## USER_ERROR: BAD_REQUEST - Common Causes and Solutions

### Overview
The `USER_ERROR: BAD_REQUEST` error occurs when CloudKit rejects requests due to schema mismatches, missing configurations, or malformed data. This guide covers the most common issues and their solutions.

---

## ✅ Implemented Fixes

### 1. Schema Initialization (CRITICAL)
**Problem:** Starting a brand new CloudKit container without initializing the schema causes BAD_REQUEST errors because CloudKit doesn't know about your record types.

**Solution:** Added automatic schema initialization in `AppDelegate.swift` (DEBUG builds only).

**What it does:**
- Creates temporary instances of all SwiftData models
- Uploads them to CloudKit to establish the schema
- Only runs in DEBUG builds to prevent production issues

**How to use:**
1. Build and run the app once on a simulator or device
2. Check the console for: `[CloudKit] Schema initialization triggered`
3. Verify the schema in CloudKit Dashboard: https://icloud.developer.apple.com/dashboard
4. Navigate to: iCloud.com.refractored.trimtally > Schema > Record Types
5. You should see: `CD_WeightEntry`, `CD_Goal`, `CD_AppSettings`, `CD_Achievement`
6. After successful initialization, comment out the schema init code in `AppDelegate`

---

## 🔍 Potential Issues to Check

### 2. CloudKit Capabilities Configuration
**Verify your entitlements are correct:**

✅ Current Configuration (Correct):
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.refractored.trimtally</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

**What to check:**
- Xcode → Project → Signing & Capabilities → iCloud
- Ensure CloudKit is checked
- Ensure the container `iCloud.com.refractored.trimtally` is selected
- Background Modes: Enable "Remote notifications"

### 3. Model Compatibility with CloudKit

SwiftData models are compatible with CloudKit, but certain features are NOT supported:

❌ **Not Supported:**
- Unique constraints (`@Attribute(.unique)`)
- Non-optional relationships without delete rules
- Binary data larger than 1MB
- Transformation attributes without proper encoding

✅ **Your Current Models (Compatible):**
- All enums are `String`-based and `Codable` ✓
- No unique constraints ✓
- Binary data (`Achievement.metadata`) is optional ✓
- All relationships are optional or properly configured ✓

### 4. Common Schema Issues

#### Issue: Missing Record Types
**Symptom:** Records fail to save with BAD_REQUEST

**Solution:**
- Run the schema initialization (see #1 above)
- Verify record types exist in CloudKit Dashboard
- SwiftData prefixes record types with `CD_` (e.g., `CD_WeightEntry`)

#### Issue: Field Name Mismatches
**Symptom:** Specific fields fail to sync

**Solution:**
- Check CloudKit Dashboard field names exactly match your model properties
- Field names are case-sensitive
- Special characters in property names may cause issues

#### Issue: Malformed Data
**Symptom:** Specific records fail with BAD_REQUEST

**Solution:**
- Ensure all `Date` properties have valid dates (not nil for non-optional)
- Ensure `Double` values are not NaN or Infinity
- Ensure `String` values don't exceed CloudKit limits (typically safe up to 1MB)

### 5. Container Identifier Mismatch
**Problem:** App uses wrong container or multiple containers

**Current Configuration:**
- Container: `iCloud.com.refractored.trimtally`
- Mode: `.automatic` (uses first container in entitlements)

**If you have multiple containers:**
```swift
// Explicitly specify container
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .init(containerIdentifier: "iCloud.com.refractored.trimtally")
)
```

---

## 🛠️ Debugging Steps

### Step 1: Verify Container Access
```swift
// Add to AppDelegate for testing
CKContainer(identifier: "iCloud.com.refractored.trimtally")
    .accountStatus { status, error in
        print("[CloudKit] Account status: \(status.rawValue)")
        if let error = error {
            print("[CloudKit] Error: \(error)")
        }
    }
```

Expected output:
- `1` = Available (signed into iCloud)
- `0` = CouldNotDetermine
- `2` = Restricted
- `3` = NoAccount

### Step 2: Enable CloudKit Logging
Add to your scheme's environment variables:
- `com.apple.coredata.CloudKitDebug`: `1`
- `com.apple.coredata.CloudKit.verbose`: `1`

This provides detailed logs about CloudKit operations.

### Step 3: Reset Development Environment
If the schema is corrupted:
1. Go to CloudKit Dashboard
2. Select your container
3. Development → Data → Reset Development Environment
4. Re-run the app to re-initialize the schema

**⚠️ WARNING:** Only reset DEVELOPMENT environment, never PRODUCTION!

### Step 4: Check iCloud Account
- Ensure the device/simulator is signed into iCloud
- Settings → [Your Name] → iCloud
- Verify iCloud Drive is enabled

---

## 📋 Schema Promotion Checklist (Before Production)

When you're ready to ship:

### Pre-Deployment Checklist
- [ ] Schema is initialized in development environment
- [ ] All 4 record types are visible in CloudKit Dashboard (Development)
  - [ ] `CD_WeightEntry`
  - [ ] `CD_Goal`
  - [ ] `CD_AppSettings`
  - [ ] `CD_Achievement`
- [ ] App has been tested with multi-device sync in development
- [ ] All CRUD operations work correctly (Create, Read, Update, Delete)
- [ ] No schema changes are planned for v1.0
- [ ] Schema design supports future expansion (additive changes only)

### Production Deployment Steps

1. **Deploy Schema to Production**
   - Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
   - Select container: `iCloud.com.refractored.trimtally`
   - Navigate to: **Development → Schema**
   - Click **"Deploy Schema to Production"** button
   - **CAREFULLY REVIEW** all record types and fields (this is irreversible!)
   - Confirm deployment

2. **Update Code for Production**
   - Comment out schema initialization in `AppDelegate.swift` (already done)
   - The code is now configured with initialization disabled
   - Build and test production configuration

3. **Verify Production Schema**
   - In CloudKit Dashboard, switch to **Production** environment
   - Navigate to: **Production → Schema → Record Types**
   - Verify all 4 record types are present with correct fields

4. **Test Production Sync**
   - Archive and distribute a TestFlight build
   - Test on real devices (not simulators) signed into iCloud
   - Verify multi-device sync works in production environment
   - Monitor for any CloudKit errors in logs

### Post-Deployment

- [x] Schema initialization code is commented out
- [ ] Production schema verified in CloudKit Dashboard
- [ ] TestFlight build tested successfully
- [ ] Multi-device sync confirmed working

**⚠️ CRITICAL REMINDER:** CloudKit schemas in production are **additive only**. You cannot:
- Delete record types
- Delete fields
- Rename record types or fields
- Change field types

For major schema changes, you must:
- Create a new CloudKit container
- Implement data migration strategy
- Version your app appropriately

---

## 🔄 Future Schema Evolution (After Production)

### Supported Changes (Safe)
✅ Add new record types
✅ Add new fields to existing record types  
✅ Add new indexes
✅ Mark fields as optional
✅ Add metadata/relationships

### Unsupported Changes (Blocked)
❌ Delete record types
❌ Delete fields
❌ Rename record types
❌ Rename fields
❌ Change field types
❌ Make fields required

### Migration Strategies

**Option 1: New Container (Breaking Change)**
- Create `iCloud.com.refractored.trimtally.v2`
- Implement data migration logic
- Migrate users gradually
- Maintain backward compatibility temporarily

**Option 2: Versioned Entities**
- Add `schemaVersion` field to records
- Filter queries by compatible versions
- Older app versions ignore newer schema

**Option 3: Additive-Only Evolution**
- Add new optional fields for new features
- Deprecated fields remain but unused
- Use app version checks for feature availability

---

## 🔧 Quick Fixes

### Fix 1: Reset Local SwiftData Store
If local data is corrupted:
```swift
// In DataManager or test code
try modelContext.delete(model: WeightEntry.self)
try modelContext.delete(model: Goal.self)
try modelContext.delete(model: AppSettings.self)
try modelContext.delete(model: Achievement.self)
try modelContext.save()
```

### Fix 2: Disable CloudKit Temporarily
Test if the issue is CloudKit-specific:
```swift
// In DataManager.init()
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: inMemory,
    cloudKitDatabase: .none  // Temporarily disable
)
```

### Fix 3: Fresh Install
1. Delete app from device/simulator
2. Reset CloudKit development environment
3. Clean Xcode build folder (Cmd+Shift+K)
4. Rebuild and reinstall

---

## 📚 Apple Documentation References

- [Syncing model data across a person's devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices/)
- [Creating a Core Data Model for CloudKit](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit/)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [ModelConfiguration.CloudKitDatabase](https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/)

---

## 🐛 Common Error Messages

### "Zone Not Found"
- Schema not initialized
- Container identifier mismatch
- Run schema initialization

### "Unknown Item"
- Record type doesn't exist in CloudKit schema
- Field name typo or mismatch
- Verify in CloudKit Dashboard

### "Invalid Arguments"
- Malformed data (NaN, Infinity, invalid Date)
- Unsupported field type
- Data exceeds size limits

### "Authentication Failed"
- Not signed into iCloud
- Container access issue
- Check accountStatus

---

## ✨ Next Steps

1. **Run the app once** to initialize the schema
2. **Check CloudKit Dashboard** to verify record types
3. **Test with sample data** (use `generateSampleData()` in DEBUG)
4. **Verify multi-device sync** with two simulators
5. **Monitor console logs** for CloudKit errors
6. **Deploy to production** when ready (irreversible!)

If you continue to see BAD_REQUEST errors after following this guide, please collect:
- Full console logs with CloudKit debugging enabled
- CloudKit Dashboard screenshots showing schema
- Specific operations that trigger the error
