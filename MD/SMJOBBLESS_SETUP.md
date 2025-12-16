# SMJobBless Setup Instructions

## Overview

The Process Monitor now uses a **privileged helper tool** installed via SMJobBless for secure, production-safe privilege escalation. This is Apple's recommended approach for apps that need system-level access.

## Architecture

```
┌─────────────────────┐         XPC          ┌──────────────────────┐
│                     │ ◄──────────────────► │                      │
│  Main App (UI)      │   Secure Channel     │  Privileged Helper   │
│  (User privileges)  │                      │  (Root privileges)   │
│                     │                      │                      │
└─────────────────────┘                      └──────────────────────┘
         │                                             │
         │                                             │
    User sees UI                        EndpointSecurity monitoring
    Filters/displays data               Code signing validation
                                        Threat detection
```

## Files Created

### 1. XPC Protocol (`PrivilegedHelperProtocol.swift`)
- Defines communication interface between app and helper
- Two protocols: app → helper and helper → app
- Type-safe method calls with completion handlers

### 2. Privileged Helper (`PrivilegedHelper/main.swift`)
- Runs as root daemon via launchd
- Implements EndpointSecurity client
- Listens on XPC mach service
- Sends events back to main app

### 3. Launchd Property List (`com.liberty.LibertyAccessControl.helper.plist`)
- Defines helper tool as system daemon
- Specifies mach service name
- Configures auto-restart and logging

### 4. Helper Manager (`PrivilegedHelperManager.swift`)
- Main app service for interacting with helper
- Handles installation via SMJobBless
- Manages XPC connection lifecycle
- Implements delegate protocol to receive events

### 5. Installation UI (`HelperInstallationView.swift`)
- User-friendly installation interface
- Shows helper status and version
- Explains what the helper does
- One-click installation with password prompt

## Xcode Configuration Required

### Step 1: Create Helper Tool Target

1. In Xcode, select **File → New → Target**
2. Choose **Command Line Tool**
3. Configure:
   - Product Name: `com.liberty.LibertyAccessControl.helper`
   - Language: Swift
   - Include in: LibertyAccessControl project
4. Click **Finish**

### Step 2: Configure Helper Target

1. Select helper target in project settings
2. **General** tab:
   - Bundle Identifier: `com.liberty.LibertyAccessControl.helper`
   - Version: `1.0.0`
   - Build: `1`

3. **Build Settings**:
   - Product Name: `com.liberty.LibertyAccessControl.helper`
   - Skip Install: NO
   - Installation Directory: `/Library/PrivilegedHelperTools`
   - Deployment Postprocessing: YES
   - Strip Debug Symbols During Copy: NO (for debugging)

4. **Build Phases**:
   - Remove "Copy Files" phase if present
   - **Link Binary With Libraries**:
     - Add `libEndpointSecurity.tbd`
     - Add `Security.framework`
     - Add `Foundation.framework`

5. **Signing & Capabilities**:
   - Signing Certificate: Same as main app
   - Add entitlements file: `PrivilegedHelper/PrivilegedHelper.entitlements`
   - Content:
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
     <dict>
         <key>com.apple.developer.endpoint-security.client</key>
         <true/>
         <key>com.apple.security.app-sandbox</key>
         <false/>
     </dict>
     </plist>
     ```

### Step 3: Add Files to Helper Target

Add these files to the helper target (check box in File Inspector):
- `PrivilegedHelper/main.swift`
- `LibertyAccessControl/Services/PrivilegedHelper/PrivilegedHelperProtocol.swift`

### Step 4: Configure Main App Info.plist

Add SMJobBless configuration to main app's `Info.plist`:

```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.liberty.LibertyAccessControl.helper</key>
    <string>anchor apple generic and identifier "com.liberty.LibertyAccessControl.helper" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = YOUR_TEAM_ID)</string>
</dict>
```

Replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID.

### Step 5: Configure Helper Info.plist

Create `PrivilegedHelper/Info.plist` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.liberty.LibertyAccessControl.helper</string>
    <key>CFBundleName</key>
    <string>LibertyAccessControl Helper</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>SMAuthorizedClients</key>
    <array>
        <string>anchor apple generic and identifier "com.liberty.LibertyAccessControl" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = YOUR_TEAM_ID)</string>
    </array>
</dict>
</plist>
```

Replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID.

### Step 6: Copy Helper to App Bundle

1. Select main app target
2. Go to **Build Phases**
3. Click **+** → **New Copy Files Phase**
4. Configure:
   - Destination: **Wrapper**
   - Subpath: `Contents/Library/LaunchServices`
   - Add: `com.liberty.LibertyAccessControl.helper` (product from helper target)
   - Code Sign On Copy: **✓** (checked)

### Step 7: Copy Launchd Plist to App Bundle

1. In same **Build Phases** tab
2. Click **+** → **New Copy Files Phase**
3. Configure:
   - Destination: **Wrapper**
   - Subpath: `Contents/Library/LaunchServices`
   - Add: `PrivilegedHelper/com.liberty.LibertyAccessControl.helper.plist`
   - Code Sign On Copy: **✗** (unchecked)

## Usage

### Installation Flow

1. User launches app and opens Process Monitor
2. Banner shows "Helper tool not installed"
3. User clicks "Setup" button
4. Installation view explains what the helper does
5. User clicks "Install Helper Tool"
6. macOS prompts for password (standard admin authorization)
7. Helper is installed to `/Library/PrivilegedHelperTools/`
8. Launchd starts helper automatically
9. App establishes XPC connection
10. Process monitoring is now available

### Development Testing

```bash
# Check if helper is installed
sudo launchctl list | grep com.liberty.LibertyAccessControl.helper

# View helper logs
sudo tail -f /var/log/com.liberty.LibertyAccessControl.helper.log
sudo tail -f /var/log/com.liberty.LibertyAccessControl.helper.error.log

# Manually unload helper (for testing)
sudo launchctl unload /Library/LaunchDaemons/com.liberty.LibertyAccessControl.helper.plist
sudo rm /Library/PrivilegedHelperTools/com.liberty.LibertyAccessControl.helper
sudo rm /Library/LaunchDaemons/com.liberty.LibertyAccessControl.helper.plist

# Reload after changes
killall com.liberty.LibertyAccessControl.helper
```

### Distribution Notes

- Helper is embedded in app bundle
- First run prompts user for password to install
- Updates handled automatically when helper version changes
- Uninstallation removes helper from system
- No manual configuration required by end users

## Security Benefits

✅ **Isolated Privileges**: Only helper runs as root, not entire app  
✅ **Code Signing**: Helper verified by macOS before installation  
✅ **XPC Sandboxing**: Secure IPC between app and helper  
✅ **User Consent**: Password required for installation  
✅ **Automatic Updates**: Helper updated when app updates  
✅ **No SIP Disabled**: Works with System Integrity Protection enabled  

## Troubleshooting

### Helper installation fails
- Check code signing certificate is valid
- Verify Team ID in Info.plist matches certificate
- Ensure helper target builds successfully
- Check helper is copied to app bundle

### XPC connection fails
- Verify helper is running: `sudo launchctl list | grep helper`
- Check mach service name matches in all files
- Review error logs in `/var/log/`
- Ensure helper has correct entitlements

### EndpointSecurity errors in helper
- Verify helper has `com.apple.developer.endpoint-security.client` entitlement
- Check helper is properly code signed
- Ensure running on macOS 10.15+ (Catalina or later)
- Note: May still require SIP disabled for development builds

## References

- [Apple TN2083: Daemons and Agents](https://developer.apple.com/library/archive/technotes/tn2083/)
- [SMJobBless Example Code](https://developer.apple.com/library/archive/samplecode/SMJobBless/Introduction/Intro.html)
- [EndpointSecurity Framework](https://developer.apple.com/documentation/endpointsecurity)
- [XPC Services](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html)
