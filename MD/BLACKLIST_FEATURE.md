# Permission Revocation & Blacklist System

## Overview

This feature provides a comprehensive permission revocation system with automatic blacklisting and attempt logging. When a user revokes a permission for an app, the system:

1. **Removes the permission** from the TCC database
2. **Adds the app to a blacklist** to prevent re-authorization
3. **Monitors for re-grant attempts** and automatically blocks them
4. **Logs all attempts** in a viewable interface

## Components

### 1. Data Models

#### `BlacklistEntry.swift`
Represents a blacklisted permission entry with:
- Service name (e.g., `kTCCServiceCamera`)
- Client identifier (app path)
- Bundle ID and Team ID (parsed from CSReq)
- Revocation timestamp
- Optional reason for revocation

#### `RevocationAttempt.swift`
Logs each attempt to regain a blacklisted permission:
- Service and client details
- Timestamp of the attempt
- Whether the attempt was blocked
- Bundle ID for identification

### 2. Services

#### `BlacklistService.swift`
Manages the blacklist and attempt logs:
- **Persistence**: Uses `UserDefaults` for storage
- **Blacklist Operations**: Add, remove, check entries
- **Attempt Logging**: Records all re-grant attempts
- **Cleanup**: Remove old attempts (7/30 days)

#### `BlacklistEnforcementService.swift`
Monitors TCC databases for blacklist violations:
- **Auto-Monitoring**: Periodic scanning (every 5 seconds by default)
- **Dual Database Check**: Monitors both User and System TCC databases
- **Automatic Revocation**: Re-removes permissions that reappear
- **Notification**: Posts system notifications on violations

### 3. Enhanced Delete Operations

#### `DeleteUserRecords.swift` (Updated)
Added `revokeAndBlacklistPermission()` method that:
1. Deletes permission from User TCC database
2. Adds to blacklist
3. Logs the revocation as an attempt

#### `DeleteSystemRecords.swift` (Updated)
Same functionality for System TCC database (requires root)

### 4. User Interface

#### `UserView.swift` (Updated)
- **Revoke Button**: Red shield icon next to allowed permissions
- **Blacklist Badge**: "BLACKLISTED" indicator for blacklisted apps
- **Confirmation Dialog**: Warns user about permanent revocation
- **Auto-Refresh**: Reloads data after revocation

#### `SystemView.swift` (Updated)
Same enhancements for system permissions

#### `BlacklistManagementView.swift` (New)
Comprehensive management interface with two tabs:

**Blacklist Tab:**
- Shows all blacklisted entries
- Search functionality
- Remove from blacklist option
- Details: service, bundle ID, team ID, revocation date, reason

**Attempts Tab:**
- Real-time log of all re-grant attempts
- Blocked vs. logged status indicators
- Clear options (all, 7 days, 30 days)
- Detailed attempt information

**Control Panel:**
- Toggle auto-enforcement on/off
- Live monitoring indicator

### 5. Integration

#### `ContentView.swift` (Updated)
Added "Blacklist Management" navigation link in the sidebar

## Usage

### For Users

1. **Revoke a Permission:**
   - Navigate to User or System permissions view
   - Find an allowed permission
   - Click the red shield icon (🛡️❌)
   - Confirm the revocation
   - Permission is removed and app is blacklisted

2. **View Blacklist:**
   - Navigate to "Blacklist Management"
   - See all blacklisted apps
   - Search by app name, bundle ID, or service
   - Remove from blacklist if needed

3. **Monitor Attempts:**
   - Switch to "Attempts" tab
   - View all re-authorization attempts
   - See which attempts were blocked
   - Clear old attempts as needed

4. **Enable Auto-Enforcement:**
   - Toggle "Auto-Enforce" in Blacklist Management
   - System will automatically re-revoke any blacklisted permissions
   - Green indicator shows monitoring is active

### For Developers

#### Add Permission to Blacklist
```swift
BlacklistService.shared.addToBlacklist(
    service: "kTCCServiceCamera",
    client: "/Applications/MyApp.app",
    bundleID: "com.example.myapp",
    teamID: "ABCD123456",
    reason: "User requested permanent revocation"
)
```

#### Check if Blacklisted
```swift
let isBlacklisted = BlacklistService.shared.isBlacklisted(
    service: "kTCCServiceCamera",
    client: "/Applications/MyApp.app"
)
```

#### Log Revocation Attempt
```swift
BlacklistService.shared.logRevocationAttempt(
    service: "kTCCServiceCamera",
    client: "/Applications/MyApp.app",
    bundleID: "com.example.myapp",
    blocked: true
)
```

#### Start/Stop Enforcement Monitoring
```swift
// Start monitoring (every 5 seconds)
BlacklistEnforcementService.shared.startMonitoring()

// Custom interval (every 10 seconds)
BlacklistEnforcementService.shared.startMonitoring(interval: 10.0)

// Stop monitoring
BlacklistEnforcementService.shared.stopMonitoring()
```

#### Revoke and Blacklist (User Database)
```swift
UserService.shared.revokeAndBlacklistPermission(
    service: "kTCCServiceCamera",
    client: "/Applications/MyApp.app",
    bundleID: "com.example.myapp",
    teamID: "ABCD123456",
    reason: "Security violation"
) { success, message in
    if success {
        print("Permission revoked and blacklisted")
    }
}
```

## Technical Details

### Monitoring Algorithm

1. **Periodic Scan**: Every N seconds (default: 5)
2. **Database Query**: Check for blacklisted apps in both TCC databases
3. **Violation Detection**: If permission exists with `auth_value = 2` (Allowed)
4. **Automatic Revocation**: Delete the permission again
5. **Logging**: Record the blocked attempt
6. **Notification**: Alert user via NotificationCenter

### Persistence

- **Blacklist**: Stored in `UserDefaults` under `com.libertyaccesscontrol.blacklist`
- **Attempts**: Stored in `UserDefaults` under `com.libertyaccesscontrol.revocation_attempts`
- **Limit**: Attempts log capped at 1000 entries
- **Format**: JSON encoded arrays

### Notification Events

Listen for blacklist violations:
```swift
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("BlacklistViolationDetected"),
    object: nil,
    queue: .main
) { notification in
    if let userInfo = notification.userInfo,
       let service = userInfo["service"] as? String,
       let client = userInfo["client"] as? String {
        print("Violation: \(client) attempted \(service)")
    }
}
```

## Security Considerations

1. **System Permissions**: System TCC database modifications require root privileges
2. **Persistence**: Blacklist survives app restarts
3. **User Control**: Users can manually remove entries from blacklist
4. **Monitoring Impact**: 5-second polling has minimal performance impact
5. **Database Safety**: Uses read-only mode for monitoring queries

## Future Enhancements

- [ ] Export/import blacklist configurations
- [ ] Custom monitoring intervals per service
- [ ] Email/push notifications for violations
- [ ] Machine learning for suspicious permission patterns
- [ ] Integration with system logs
- [ ] Whitelist exceptions for trusted apps
- [ ] Scheduled blacklist reviews/reports

## Troubleshooting

### Permission Not Being Blocked
- Check that auto-enforcement is enabled
- Verify blacklist entry exists
- Check console logs for errors
- Ensure app has proper database access

### High CPU Usage
- Increase monitoring interval: `startMonitoring(interval: 10.0)`
- Reduce number of blacklist entries
- Check for database corruption

### Blacklist Not Persisting
- Verify UserDefaults access
- Check for storage limits
- Review app sandbox permissions

## Example Workflows

### Complete Revocation Flow
```swift
// 1. User clicks revoke button
// 2. Confirmation dialog appears
// 3. On confirm:
UserService.shared.revokeAndBlacklistPermission(
    service: entry.service,
    client: entry.client,
    bundleID: entry.parsedBundleID,
    teamID: entry.parsedTeamID
) { success, message in
    // 4. Database updated
    // 5. Blacklist updated
    // 6. Attempt logged
    // 7. UI refreshed
    viewModel.loadTCCData()
}
```

### Monitoring Lifecycle
```swift
// App startup
BlacklistEnforcementService.shared.startMonitoring()

// Background monitoring...
// (automatically re-revokes any violations)

// App shutdown
BlacklistEnforcementService.shared.stopMonitoring()
```

## Testing

### Manual Testing
1. Grant an app a permission (e.g., Camera)
2. Revoke using the shield icon
3. Verify app appears in blacklist
4. Try to re-grant permission via System Settings
5. Verify auto-enforcement blocks it
6. Check attempts log for the blocked attempt

### Unit Test Ideas
- Blacklist add/remove operations
- Attempt logging and cleanup
- Monitoring enable/disable
- Database query accuracy
- Persistence across restarts
