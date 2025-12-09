# Process Monitor Setup Instructions

The Process Monitor feature requires the EndpointSecurity framework and special entitlements.

## Required Setup Steps:

### 1. Add EndpointSecurity Framework
1. Open the project in Xcode
2. Select the **LibertyAccessControl** target
3. Go to **Build Phases** → **Link Binary With Libraries**
4. Click **+** and add **EndpointSecurity.framework**

### 2. Add Entitlements File
1. Select the **LibertyAccessControl** target
2. Go to **Signing & Capabilities**
3. Under **Code Signing Entitlements**, set the path to:
   ```
   LibertyAccessControl/LibertyAccessControl.entitlements
   ```

The entitlements file has already been created with:
- `com.apple.developer.endpoint-security.client` - Required for process monitoring
- `com.apple.security.app-sandbox` set to `false` - Required for full system access

### 3. Development Requirements

**For Development/Testing:**
- **Disable SIP (System Integrity Protection)** - Required for development
  ```bash
  # Restart in Recovery Mode (Cmd+R on boot)
  # Open Terminal and run:
  csrutil disable
  # Reboot
  ```

- **Run with sudo** - EndpointSecurity requires root privileges
  ```bash
  sudo /path/to/LibertyAccessControl.app/Contents/MacOS/LibertyAccessControl
  ```

**For Distribution:**
- Must be signed with Apple Developer ID
- Must have proper provisioning profile with EndpointSecurity entitlement
- Users must approve Full Disk Access in System Preferences → Security & Privacy

### 4. Alternative: Conditional Compilation

If you want to build without EndpointSecurity support, you can disable the Process Monitor feature by:

1. Comment out or remove the Process Monitor service initialization
2. Remove the Process Monitor tab from ContentView
3. The rest of the app will work without it

### 5. Testing

Once configured:
1. Build and run the app
2. Navigate to the **Process Monitor** tab
3. Click the **Play** button to start monitoring
4. You should see process execution events in real-time

### Troubleshooting

**"Failed to create EndpointSecurity client"**
- Make sure SIP is disabled (for development)
- Run with sudo
- Check that entitlements are properly set

**Linker errors for EndpointSecurity symbols**
- Add EndpointSecurity.framework to **Link Binary With Libraries**

**"App is damaged and can't be opened"**
- This is a Gatekeeper issue with unsigned apps
- Right-click → Open, or run: `sudo xattr -cr /path/to/app`

## Security Note

The EndpointSecurity framework is a powerful kernel-level API. In production:
- Only enable Process Monitor when needed
- Properly validate and sanitize all process data
- Consider implementing rate limiting
- Log all monitoring activities for audit trails
