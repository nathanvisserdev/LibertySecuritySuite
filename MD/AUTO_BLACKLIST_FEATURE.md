# Automatic Suspicious Permission Detection & Blacklisting

## Overview

This system automatically detects and blacklists apps that are accessing permissions they shouldn't have. It maintains a whitelist of known legitimate apps and their expected permissions, then scans for violations on app launch and on-demand.

## Components

### 1. Known Apps Whitelist (`KnownAppsWhitelist.swift`)

Maintains profiles of legitimate apps with their expected permissions:

**Categories Covered:**
- **Apple System Apps**: Safari, FaceTime, Mail, Photos, Finder, Calendar, Contacts
- **Communication Apps**: Teams, Zoom, Slack, Webex, Skype
- **Development Tools**: Xcode, VS Code, Terminal, iTerm2
- **Browsers**: Chrome, Firefox, Brave, Safari
- **Productivity Apps**: Microsoft Office, Adobe Photoshop, Pages
- **Security & Utilities**: 1Password, Dropbox, Time Machine

**Profile Structure:**
```swift
AppPermissionProfile(
    bundleID: "com.apple.Safari",
    appName: "Safari",
    allowedServices: [
        "kTCCServiceCamera",
        "kTCCServiceMicrophone",
        "kTCCServiceScreenCapture"
    ],
    description: "Web browser - needs media access"
)
```

### 2. Suspicious Permission Scanner (`SuspiciousPermissionScanner.swift`)

Scans both User and System TCC databases for violations:

**Detection Logic:**
1. **Unknown Apps**: Apps not in whitelist with ANY granted permissions
2. **Unauthorized Permissions**: Known apps with permissions beyond their profile
3. **Bundle ID Extraction**: Extracts from path or CSReq blob for accurate identification

**Scan Process:**
```swift
scanner.scanAllDatabases { suspiciousApps in
    // Auto-blacklist or review
}
```

### 3. Enhanced Blacklist Model

Updated `BlacklistEntry` with comprehensive metadata:
- `allRevokedServices`: All permissions revoked for the app
- `wasAutomaticallyBlacklisted`: Flag for auto-detected violations
- `reason`: Detailed explanation of why app was blacklisted
- Access attempt tracking integrated with entry display

### 4. Comprehensive Blacklist View

Enhanced `BlacklistManagementView` with:
- **Auto/Manual Badges**: Visual indicator for auto-blacklisted apps
- **All Revoked Permissions**: Expandable list of all services blocked
- **Access Attempts Counter**: Shows how many times app tried to regain access
- **Scan Button**: On-demand suspicious permission scanning
- **Team ID Display**: Shows developer team identifier
- **Ban Timestamp**: When the app was blacklisted

### 5. Automatic Launch Scanning

Integrated in `LibertyAccessControlApp.swift`:
- Runs security scan on every app launch
- Automatically blacklists suspicious apps
- Starts enforcement monitoring
- Posts notifications for blacklisted apps

## Usage

### For Users

#### Automatic Protection
1. **App Launch**: Automatic scan runs on startup
2. **Detection**: System identifies suspicious permissions
3. **Auto-Blacklist**: Violations are immediately blacklisted
4. **Notification**: User is informed of actions taken

#### Manual Scanning
1. Navigate to **Blacklist Management**
2. Click **"Scan Now"** button
3. Review detected suspicious apps
4. Confirm to blacklist all or cancel

#### Review Blacklisted Apps
- View all blacklisted apps with full details
- See all revoked permissions per app
- Check access attempt history
- Remove from blacklist if needed

### For Developers

#### Add App to Whitelist
```swift
// In KnownAppsWhitelist.swift
AppPermissionProfile(
    bundleID: "com.mycompany.myapp",
    appName: "My App",
    allowedServices: [
        "kTCCServiceCamera",
        "kTCCServiceMicrophone"
    ],
    description: "Video calling app"
)
```

#### Check if App is Suspicious
```swift
let scanner = SuspiciousPermissionScanner()

scanner.scanAllDatabases { suspiciousApps in
    for app in suspiciousApps {
        print("Suspicious: \(app.bundleID)")
        print("Unauthorized: \(app.unauthorizedServices)")
    }
}
```

#### Manually Blacklist Suspicious App
```swift
scanner.autoBlacklistSuspiciousApps(
    suspiciousApps: [app]
) { count in
    print("Blacklisted \(count) app(s)")
}
```

## Detection Examples

### Example 1: Unknown App
```
App: com.unknown.sketchy
Granted: kTCCServiceCamera, kTCCServiceMicrophone, kTCCServiceScreenCapture
Action: BLACKLIST (not in whitelist)
Reason: "Unknown app with granted permissions"
```

### Example 2: Known App with Unauthorized Permission
```
App: com.apple.TextEdit
Granted: kTCCServiceCamera (NOT in profile)
Expected: kTCCServiceSystemPolicyDocumentsFolder only
Action: BLACKLIST
Reason: "Unauthorized permissions detected: kTCCServiceCamera"
```

### Example 3: Legitimate App
```
App: com.apple.Safari
Granted: kTCCServiceCamera, kTCCServiceMicrophone
Expected: (matches profile)
Action: ALLOW (all permissions authorized)
```

## Security Features

### Multi-Layer Protection

1. **Whitelist-Based**: Only known apps with expected permissions are allowed
2. **Auto-Detection**: Scans on launch and on-demand
3. **Immediate Blacklisting**: Suspicious apps blocked automatically
4. **Continuous Monitoring**: BlacklistEnforcementService prevents re-authorization
5. **Audit Trail**: All attempts logged with timestamps

### Attack Prevention

- **Zero-Day Apps**: Unknown apps immediately flagged
- **Privilege Escalation**: Known apps requesting unexpected permissions caught
- **Persistent Threats**: Re-authorization attempts blocked and logged
- **User Awareness**: Visual indicators and detailed reasons

## Whitelist Management

### Adding New Apps

1. Identify legitimate app needing permissions
2. Determine required services (check app documentation)
3. Add to appropriate category in `KnownAppsWhitelist.swift`
4. Test to ensure not flagged as suspicious

### Permission Services Reference

Common TCC services:
- `kTCCServiceCamera` - Camera access
- `kTCCServiceMicrophone` - Microphone access
- `kTCCServiceScreenCapture` - Screen recording
- `kTCCServiceAccessibility` - Accessibility features
- `kTCCServiceSystemPolicyAllFiles` - Full disk access
- `kTCCServiceAddressBook` - Contacts
- `kTCCServiceCalendar` - Calendar
- `kTCCServicePhotos` - Photo library
- `kTCCServiceLocation` - Location services

## UI Features

### Blacklist Card Display

**For Each Blacklisted App:**
- Bundle ID (or client path)
- AUTO badge if automatically detected
- Full list of revoked permissions
- Ban timestamp
- Team ID (if available)
- Access attempts counter
- Reason for blacklisting
- Color-coded: Orange for auto, Red for manual

### Search & Filter
- Search by bundle ID, app name, or client path
- Filter by auto vs manual blacklist
- Sort by ban date

### Scan Controls
- **Scan Now**: Manual trigger for on-demand scanning
- **Auto-Enforce**: Toggle continuous monitoring
- **Live Status**: Green indicator when monitoring active

## Performance Considerations

### Scan Frequency
- **On Launch**: One-time comprehensive scan
- **Manual**: User-triggered via UI
- **Enforcement**: Every 5 seconds (only checks blacklisted entries)

### Database Access
- Read-only access for scanning
- Minimal performance impact
- Async operations prevent UI blocking

### Storage
- Blacklist persists in UserDefaults
- Attempt log capped at 1000 entries
- Automatic old entry cleanup available

## Troubleshooting

### False Positives

**Symptom**: Legitimate app blacklisted
**Solution**: 
1. Remove from blacklist in UI
2. Add to whitelist in code
3. Rescan to verify

### App Not Detected

**Symptom**: Suspicious app not caught
**Solution**:
1. Verify app has granted permissions (auth_value = 2)
2. Check if bundle ID extraction working
3. Review scanner logs

### High CPU on Launch

**Symptom**: Slow app startup
**Solution**:
- Scan is async and shouldn't block
- Check database size
- Review number of installed apps

## Example Workflows

### Workflow 1: Clean System
```
1. App launches
2. Scanner checks all permissions
3. No violations found
4. User notified: "No suspicious apps"
5. Enforcement monitoring starts
```

### Workflow 2: Suspicious App Detected
```
1. App launches
2. Scanner finds unknown app with camera access
3. App auto-blacklisted
4. Permission revoked from TCC database
5. Attempt logged
6. User notified: "1 suspicious app blacklisted"
7. App appears in Blacklist Management view
```

### Workflow 3: Known App Violation
```
1. Manual scan triggered
2. TextEdit found with camera permission
3. Alert shown: "1 app with unauthorized permissions"
4. User confirms blacklist
5. Camera permission revoked
6. TextEdit blacklisted with reason
7. Any future camera requests auto-blocked
```

## Future Enhancements

- [ ] Machine learning for permission patterns
- [ ] Network-based threat intelligence
- [ ] Export/import whitelist configurations
- [ ] Scheduled automatic scans
- [ ] Email alerts for critical violations
- [ ] Temporary whitelist exceptions
- [ ] Integration with system security logs
- [ ] Community-driven whitelist database

## Testing

### Manual Test Scenarios

1. **Clean Scan**: Launch with only Apple apps → No detections
2. **Unknown App**: Grant camera to unknown app → Auto-blacklisted
3. **Unauthorized Permission**: Grant TextEdit camera access → Detected and flagged
4. **Whitelist Override**: Remove from blacklist → Rescan shows clean
5. **Re-authorization Attempt**: Try to re-grant blacklisted permission → Blocked and logged
