# TCC Cache Interception - Complete Guide

## Current Status

✅ **Built:**
- TCC hook dylib (`libtcchook.dylib`) - Hooks NSCache operations
- tccd wrapper binary (`tccd_wrapper`) - Executes original tccd with hook injected
- Complete analysis of tccd binary with exact addresses

❌ **Blocked By:**
- Signed System Volume (SSV) - Can't replace `/System/Library/...` files even with SIP disabled
- Library Validation - Prevents DYLD_INSERT_LIBRARIES on system binaries

## Solutions

### Option 1: Disable SSV (Most Direct)

**Steps:**
1. Reboot into Recovery Mode (hold Cmd+R during startup)
2. Open Terminal
3. Run: `csrutil disable`
4. Run: `csrutil authenticated-root disable`
5. Reboot

Then run:
```bash
cd LibertyAccessControl/Services/CacheInjection
./replace_tccd_binary.sh
```

**Pros:** Direct control over tccd
**Cons:** Disables important security feature, requires reboot

---

### Option 2: Read TCC Database Directly (Recommended for Your App)

Instead of hooking tccd, your app can:

1. **Read the TCC database** at `/Library/Application Support/com.apple.TCC/TCC.db`
2. **Monitor with FSEvents** for changes
3. **Build an in-memory cache** in your app
4. **Query your cache** instead of relying on tccd's

**This works WITHOUT:**
- Disabling SIP/SSV
- Modifying system files
- External injection
- Root access (for reading)

Your app already has `TCCCacheReader.swift` - we can enhance it!

---

### Option 3: EndpointSecurity Framework (Professional Solution)

Use Apple's official framework for monitoring TCC events:

1. Request `com.apple.developer.endpoint-security.client` entitlement
2. Subscribe to ES_EVENT_TYPE_AUTH_OPEN, ES_EVENT_TYPE_NOTIFY_EXEC
3. Monitor all app launches and file access
4. Build your blacklist enforcement on top

**Pros:** Official Apple API, no hacks needed
**Cons:** Requires special entitlement (developer account), more complex

---

## What We Discovered

### TCC Cache Location
- **Address:** `0x00000001000390a8` (NSCache allocation)
- **Type:** NSCache object
- **Storage:** Offset +0x10 in AdhocSignatureCache object
- **Name:** `"com.apple.tcc.AdhocSignatureCache"`

### Key SQL Query (What We Need to Replicate)
```sql
SELECT auth_value, auth_reason, csreq, 
       strftime('%s','now') - last_modified AS age, 
       flags, auth_version, pid, pid_version, 
       boot_uuid, last_reminded 
FROM access 
WHERE service = ? AND client = ? AND client_type = ?
```

### Hook Points Identified
1. `0x00000001000390a8` - NSCache allocation
2. `0x000000010000ed6c` - Authorization database query
3. `0x00000001000358b0` - Authorization evaluation function
4. NSCache `-setObject:forKey:` - Cache writes
5. NSCache `-objectForKey:` - Cache reads

---

## Recommendation

For your **Liberty Access Control** app, I recommend **Option 2** (direct database reading):

### Why:
1. ✅ Works without system modifications
2. ✅ Can ship to users (no complex setup)
3. ✅ Reliable and maintainable
4. ✅ You already have the code structure
5. ✅ Fast enough for real-time monitoring

### Implementation:
1. Enhance `TCCCacheReader.swift` to load entire database
2. Add FSEvents monitoring for `/Library/Application Support/com.apple.TCC/`
3. Build in-memory cache with same structure as tccd
4. Use for blacklist checks and suspicious activity detection

Want me to implement this approach?

---

## Files Created

### Analysis & Documentation
- `TCC_CACHE_ANALYSIS.md` - Complete technical analysis
- `INTERCEPTOR_SETUP.md` - Frida setup guide
- `tccdConverted_Full.c` - Pseudo-code with 1,078 functions

### Hook Implementation
- `tccd_hook.m` - Objective-C dylib that hooks NSCache
- `tccd_wrapper.c` - Binary wrapper for tccd
- `build_hook.sh` - Builds the dylib
- `build_wrapper.sh` - Builds the wrapper
- `inject_into_tccd.sh` - Injection script
- `replace_tccd_binary.sh` - Binary replacement script

### Frida Alternative
- `tccd_cache_interceptor.js` - Frida script
- `run_tccd_interceptor.sh` - Frida runner

All ready to use once SSV is disabled, OR we can pivot to the in-app solution.
