# tccd Cache Injection Framework

This framework allows you to hook into tccd's AdhocSignatureCache and intercept/modify cache operations.

## Components

- **tccd_hook.c** - The injection dylib that hooks into tccd
- **build_and_inject.sh** - Build and usage instructions
- **tccd_hook.log** - Runtime log (created in /tmp)

## What It Does

The hook intercepts:
1. `malloc_type_calloc` - Catches cache allocation at 0x1000395cc
2. `dispatch_queue_create` - Captures the "com.apple.tcc.AdhocSignatureCache" queue
3. NSCache operations - Monitors cache reads/writes

## Requirements

⚠️ **CRITICAL**: Requires System Integrity Protection (SIP) to be disabled
- This is for research/testing only
- Your system will be less secure with SIP disabled
- Only use on a test machine

## Build

```bash
cd tccd_injector
./build_and_inject.sh
```

## Usage

1. **Disable SIP** (one-time setup):
   - Reboot into Recovery Mode (hold Command+R at startup)
   - Open Terminal
   - Run: `csrutil disable`
   - Reboot

2. **Kill existing tccd**:
   ```bash
   sudo killall tccd
   ```

3. **Inject the hook**:
   ```bash
   # For system tccd (requires root)
   sudo DYLD_INSERT_LIBRARIES=/full/path/to/tccd_hook.dylib \
       /System/Library/PrivateFrameworks/TCC.framework/Support/tccd system &
   
   # For user tccd
   DYLD_INSERT_LIBRARIES=/full/path/to/tccd_hook.dylib \
       /System/Library/PrivateFrameworks/TCC.framework/Support/tccd &
   ```

4. **Monitor activity**:
   ```bash
   tail -f /tmp/tccd_hook.log
   ```

## What You'll See

The log will show:
- When the AdhocSignatureCache is allocated
- The memory address of the cache
- The cache name ("tccd AdhocSignatureCache")
- Dispatch queue creation
- Cache allocation count and size

Example output:
```
=== tccd_hook loaded at 1733615234 ===
[HOOK] tccd_hook.dylib initializing...
[HOOK] PID: 12345
[HOOK] malloc_type_calloc: count=1, size=456 (0x1c8), ptr=0x600001234000, allocation#1
[HOOK] *** Captured AdhocSignatureCache at 0x600001234000 ***
[HOOK] Cache name: tccd AdhocSignatureCache
[HOOK] *** Captured AdhocSignatureCache dispatch queue: com.apple.tcc.AdhocSignatureCache ***
```

## Next Steps

To actually modify cache entries, you would:
1. Parse the cache structure at the captured pointer
2. Locate the NSCache object at offset +0x10
3. Hook NSCache's `objectForKey:` and `setObject:forKey:` methods
4. Intercept lookups and return modified signatures

## Cleanup

```bash
# Kill hooked tccd
sudo killall tccd

# tccd will restart normally without the hook

# Re-enable SIP when done (in Recovery Mode)
csrutil enable
```

## Legal Notice

This is for educational and security research purposes only. Modifying system processes may violate your computer's security policies or local laws. Use responsibly.
