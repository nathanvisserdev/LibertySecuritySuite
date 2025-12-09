# TCC Cache Interceptor - Setup & Usage

## Quick Start

### 1. Install Frida (if not already installed)
```bash
pip3 install frida-tools
```

### 2. Disable SIP (System Integrity Protection) - Required
Frida needs to attach to system processes like tccd.

```bash
# Reboot into Recovery Mode (hold Cmd+R during startup)
# In Terminal:
csrutil disable
# Reboot normally
```

### 3. Run the Interceptor
```bash
sudo ./run_tccd_interceptor.sh
```

## What It Does

The Frida script hooks into the `tccd` daemon at these critical points:

1. **NSCache Allocation** (`0x390a8`) - Captures when tccd creates its authorization cache
2. **NSCache Storage** (`0x390b4`) - **MAIN TARGET** - Captures the cache pointer
3. **Authorization Query** (`0xed6c`) - Monitors database queries for permissions
4. **Authorization Evaluation** (`0x358b0`) - Logs all permission decisions
5. **NSCache Operations** - Tracks all cache reads/writes

## Expected Output

```
[*] TCC Cache Interceptor loaded
[+] tccd base address: 0x100000000
[*] Hooking NSCache allocation at: 0x100390a8
[*] Hooking NSCache storage at: 0x1003390b4
[*] Waiting for tccd to allocate TCC cache...

[+] ********************************************
[+] TCC CACHE CAPTURED!
[+] ********************************************
[+] NSCache pointer: 0x600001234560
[+] Cache name: com.apple.tcc.AdhocSignatureCache

[★] AUTHORIZATION EVALUATION
    Service: kTCCServiceCamera
    Subject: com.apple.FaceTime
    → Result: Allowed
```

## Interactive Commands

Once running, you can use these commands in the Frida REPL:

```javascript
// Dump all captured authorization records
%resume
dumpCache()

// Get the NSCache pointer
getCache()

// Inspect cache contents
inspectCache()

// Get record count
getRecordCount()
```

## Capturing the Cache for Your App

Once you have the NSCache pointer, you can:

### Option A: Export to File
Add this to the Frida script:
```javascript
var fs = require('fs');
fs.writeFileSync('tcc_cache_dump.json', JSON.stringify(authorizationRecords, null, 2));
```

### Option B: Use XPC to communicate with your app
Your Swift app can connect to the Frida script via XPC and query the cache in real-time.

### Option C: Monitor and react
The script already logs every authorization decision. You can:
- Block suspicious apps
- Alert on permission changes
- Maintain a local database mirror

## Troubleshooting

### "Operation not permitted"
- Make sure SIP is disabled
- Run with `sudo`
- Check that tccd is running: `pgrep tccd`

### "tccd not found"
- tccd starts on demand
- Trigger it by: Opening System Settings → Privacy & Security
- Or manually: `sudo launchctl load /System/Library/LaunchDaemons/com.apple.tccd.plist`

### Frida crashes on attach
- tccd might be protected even with SIP disabled
- Try: `sudo killall tccd` then let it restart
- Check for any security software blocking Frida

## Next Steps

1. **Test the interceptor** - Run it and trigger some permission requests
2. **Capture the cache pointer** - You'll see it in the output
3. **Integrate with your app** - Use XPC or shared memory to communicate
4. **Build your features** - Blacklist enforcement, monitoring, alerts

## Security Note

This tool requires:
- ✅ SIP disabled (one-time, user does it)
- ✅ Sudo/root access (for attaching to tccd)
- ✅ User consent (it's their machine)

Perfect for:
- 🔒 Security monitoring tools
- 🛡️ Privacy protection apps
- 🔍 Forensics/analysis tools
- 📊 System administrators

## Files Created

- `tccd_cache_interceptor.js` - Main Frida script
- `run_tccd_interceptor.sh` - Convenience runner
- `TCC_CACHE_ANALYSIS.md` - Technical documentation
- `tccdConverted_Full.c` - Full pseudo-code conversion
