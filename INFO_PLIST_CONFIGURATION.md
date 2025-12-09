# Info.plist Configuration Quick Reference

## Main App Info.plist

Add this entry to `LibertyAccessControl/Info.plist`:

```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.liberty.LibertyAccessControl.helper</key>
    <string>anchor apple generic and identifier "com.liberty.LibertyAccessControl.helper" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = YOUR_TEAM_ID)</string>
</dict>
```

**Replace** `YOUR_TEAM_ID` with your Apple Developer Team ID (found in Xcode: Select target → Signing & Capabilities)

---

## Helper Info.plist

Create `PrivilegedHelper/Info.plist`:

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

**Replace** `YOUR_TEAM_ID` with your Apple Developer Team ID (same as above)

---

## Helper Entitlements

Create `PrivilegedHelper/PrivilegedHelper.entitlements`:

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

---

## Finding Your Team ID

### Method 1: Xcode
1. Open Xcode project
2. Select main app target
3. Go to **Signing & Capabilities** tab
4. Look for **Team** dropdown - your Team ID is shown in parentheses
5. Example: "Nathan Visser (ABC123XYZ)"  →  Team ID is `ABC123XYZ`

### Method 2: Developer Portal
1. Go to https://developer.apple.com/account
2. Click **Membership**
3. Your Team ID is listed under **Membership Information**

### Method 3: Keychain
1. Open **Keychain Access** app
2. Select **My Certificates**
3. Double-click your Developer certificate
4. Look for **Organizational Unit (OU)** in the Subject Name
5. That's your Team ID

---

## Code Signing Requirements Explained

The long string in `SMPrivilegedExecutables` and `SMAuthorizedClients` is a **code signing requirement**. It ensures:

- **anchor apple generic**: Certificate issued by Apple
- **identifier**: Bundle ID must match exactly
- **certificate leaf[...].1.9**: Mac App Distribution certificate
- **certificate 1[...].2.6**: Developer ID certificate  
- **certificate leaf[...].1.13**: Mac App certificate
- **certificate leaf[subject.OU]**: Team ID must match

This prevents unauthorized apps from:
- Installing malicious helpers pretending to be yours
- Connecting to your helper tool

---

## Verification

After configuration, verify with:

```bash
# Check main app code signing
codesign -d -r- /path/to/LibertyAccessControl.app

# Check helper code signing
codesign -d -r- /Library/PrivilegedHelperTools/com.liberty.LibertyAccessControl.helper

# Both should show the same Team ID
```

---

## Common Mistakes

❌ Forgetting to replace `YOUR_TEAM_ID`  
❌ Mismatched Team IDs between app and helper  
❌ Missing entitlements file for helper  
❌ Wrong bundle identifier format  
❌ Not code signing helper during copy  

✅ Use exact same Team ID in both plists  
✅ Bundle IDs must match code signing identity  
✅ Helper must be code signed with same certificate as app  
✅ Test with `SMJobBless` API errors enabled  
