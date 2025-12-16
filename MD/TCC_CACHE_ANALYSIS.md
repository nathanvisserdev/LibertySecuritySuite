# TCC Cache Allocation Analysis

## Executive Summary
Analysis of the `tccd` binary disassembly reveals the exact memory locations where TCC (Transparency, Consent, and Control) caches are allocated and managed.

---

## 1. NSCache Allocation (AdhocSignatureCache)

### Primary Cache Structure
**Location:** `0x00000001000390a8`  
**Type:** `NSCache` (Objective-C)  
**Purpose:** Caches application signatures for quick access validation

```c
// Address: 0x00000001000390a4 - 0x00000001000390bc
adrp    x8, 91 ; 0x100094000
ldr     x0, [x8, #0xcb8]  // Load _OBJC_CLASS_$_NSCache
bl      _objc_alloc_init  // Allocate and initialize NSCache
ldr     x8, [x20, #0x10]  // Load existing cache pointer
str     x0, [x20, #0x10]  // Store new cache at offset +0x10
mov     x0, x8
bl      _objc_release     // Release old cache
```

**Key Details:**
- Cache stored at object offset `+0x10` (16 bytes)
- Associated with dispatch queue: `"com.apple.tcc.AdhocSignatureCache"`
- Also has `NSMutableDictionary` at offset `+0x8` for metadata

### Cache Initialization Function
**Function Start:** `0x0000000100038f48` (approximate)  
**Initialization Sequence:**
1. Creates `NSMutableDictionary` at offset `+0x8`
2. Creates `NSCache` at offset `+0x10`
3. Creates dispatch queue for thread-safe access
4. Sets up cache eviction policies

---

## 2. Authorization Database Cache

### Database Query Cache Points

#### Primary Authorization Lookup
**Address:** `0x000000010000ed6c`  
**SQL Query:**
```sql
SELECT auth_value, auth_reason, csreq, 
       strftime('%s','now') - last_modified AS age, 
       flags, auth_version, pid, pid_version, 
       boot_uuid, last_reminded 
FROM access 
WHERE service = ? AND client = ? AND client_type = ?
```

**This is the HOT PATH for authorization checks** - caching this query would intercept most TCC decisions.

#### Indirect Object Authorization
**Address:** `0x00000001000170c0`  
**SQL Query:**
```sql
SELECT auth_value, auth_reason, csreq, 
       indirect_object_code_identity, 
       strftime('%s','now') - last_modified AS age 
FROM access 
WHERE service = ? AND client = ? AND client_type = ? 
      AND indirect_object_identifier = ? 
      AND (flags IS NULL OR (flags & 1) == 0)
```

---

## 3. Critical Hook Points for Cache Interception

### Hook Point #1: Cache Initialization
**Address:** `0x00000001000390a8`  
**Function:** NSCache allocation for AdhocSignatureCache  
**Strategy:** Hook `objc_alloc_init` calls and track cache object pointer

```c
// Pseudo-code for hook
void* hooked_objc_alloc_init(Class cls) {
    void* result = original_objc_alloc_init(cls);
    
    // Check if this is NSCache class
    if (strcmp(class_getName(cls), "NSCache") == 0) {
        NSLog(@"[HOOK] NSCache allocated at: %p", result);
        // Store reference to intercept later
        g_tcc_cache = result;
    }
    
    return result;
}
```

### Hook Point #2: Authorization Query Execution
**Address:** `0x000000010000ed6c`  
**Function:** Database query for authorization status  
**Strategy:** Hook SQLite execution or result processing

```c
// Hook the function that executes this query
// Function address needs to be determined from context
void* hooked_get_authorization_record(void* service, void* client, int type) {
    NSLog(@"[HOOK] Authorization check: %@ -> %@", client, service);
    
    // Check our whitelist/blacklist
    if (should_block(client, service)) {
        return create_denied_result();
    }
    
    // Call original
    void* result = original_get_authorization_record(service, client, type);
    return result;
}
```

### Hook Point #3: Authorization Evaluation
**Address:** `0x00000001000358b0`  
**Method:** `-[TCCDServer evaluateComposedAuthorizationToService:andAccessSubject:withRelation:authorizationResult:authorizationReason:subjectCodeIdentityDataResult:]`

**This is the MASTER evaluation function** - hooking this gives complete control.

```objc
// Objective-C method swizzling target
@interface TCCDServer : NSObject
- (id)evaluateComposedAuthorizationToService:(id)service
                           andAccessSubject:(id)subject
                               withRelation:(id)relation
                       authorizationResult:(id*)result
                       authorizationReason:(id*)reason
             subjectCodeIdentityDataResult:(id*)identity;
@end

// Hook implementation
id hooked_evaluateComposedAuthorizationToService(
    TCCDServer* self, SEL _cmd,
    id service, id subject, id relation,
    id* result, id* reason, id* identity) {
    
    NSLog(@"[HOOK] Authorization evaluation for: %@", service);
    
    // Apply our policy
    if (is_blacklisted(subject, service)) {
        *result = @(0); // Denied
        *reason = @(1000); // Custom reason
        return nil;
    }
    
    // Call original
    return original_evaluateComposedAuthorizationToService(
        self, _cmd, service, subject, relation,
        result, reason, identity);
}
```

---

## 4. Cache Structure Analysis

### AdhocSignatureCache Object Layout
Based on the disassembly, the cache object has this structure:

```c
struct AdhocSignatureCache {
    void* isa;                           // +0x0  Objective-C class pointer
    NSMutableDictionary* metadata;       // +0x8  Metadata dictionary
    NSCache* cache;                      // +0x10 Main NSCache object
    // ... other fields ...
    dispatch_queue_t queue;              // +0x38 Serial queue for thread safety
};
```

### Cache Operations
The cache supports:
1. **Lookup** - Check if signature exists in memory
2. **Insert** - Add new signature to cache
3. **Evict** - Remove LRU items when capacity exceeded
4. **Persist** - Write to disk cache

**Capacity Management:**
- Address `0x000000010003a45c`: "Cache size exceeds capacity, evicting lru items"
- Address `0x000000010003a5f0`: "Evicted cached signature"

---

## 5. Database Access Patterns

### Write Operations (for cache invalidation monitoring)

**INSERT/REPLACE:**  
Address: `0x00000001000192a8`
```sql
INSERT OR REPLACE INTO access 
(service, client, client_type, auth_value, auth_reason, 
 auth_version, csreq, policy_id, indirect_object_identifier_type, 
 indirect_object_identifier, indirect_object_code_identity, flags) 
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
```

**UPDATE:**  
Address: `0x000000010000f8a4`
```sql
UPDATE access 
SET flags = ? 
WHERE service = ? AND client = ? AND client_type = ?
```

### Hook Strategy for Cache Invalidation
Monitor these write operations to know when to invalidate our own cache:

```c
void monitor_database_writes() {
    // Hook sqlite3_step at these addresses
    hook_function(0x00000001000192a8, hooked_insert_replace);
    hook_function(0x000000010000f8a4, hooked_update_flags);
}
```

---

## 6. Practical Implementation Guide

### Step 1: Identify Cache Object
```c
// Use Frida to find the cache object
Interceptor.attach(Module.findExportByName(null, 'objc_alloc_init'), {
    onEnter: function(args) {
        var className = ObjC.Object(args[0]).toString();
        if (className === 'NSCache') {
            console.log('[+] NSCache being allocated');
            this.isCache = true;
        }
    },
    onLeave: function(retval) {
        if (this.isCache) {
            console.log('[+] NSCache instance:', retval);
            // Store this pointer for later manipulation
        }
    }
});
```

### Step 2: Hook Authorization Checks
```c
// Hook the authorization evaluation function
var tccdBase = Module.findBaseAddress('tccd');
Interceptor.attach(tccdBase.add(0x358b0), {
    onEnter: function(args) {
        console.log('[+] Authorization evaluation');
        console.log('    Service:', ObjC.Object(args[2]));
        console.log('    Subject:', ObjC.Object(args[3]));
        
        // Modify behavior if needed
        if (shouldBlock(args[2], args[3])) {
            // Modify the authorization result
            args[5] = ptr(0); // Denied
        }
    }
});
```

### Step 3: Direct Cache Manipulation
```c
// Once we have the NSCache object reference
var cache = ObjC.Object(ptr('0xCACHE_ADDRESS_HERE'));

// Read from cache
var key = ObjC.classes.NSString.stringWithString_('com.example.app');
var value = cache.objectForKey_(key);

// Write to cache
cache.setObject_forKey_(myObject, key);

// Clear cache
cache.removeAllObjects();
```

---

## 7. Summary of Critical Addresses

| Address | Purpose | Hook Priority |
|---------|---------|---------------|
| `0x00000001000390a8` | NSCache allocation | HIGH |
| `0x00000001000358b0` | Authorization evaluation | CRITICAL |
| `0x000000010000ed6c` | Primary auth query | HIGH |
| `0x00000001000170c0` | Indirect object auth | MEDIUM |
| `0x00000001000192a8` | Insert/replace permission | MEDIUM |
| `0x000000010000f8a4` | Update permission flags | MEDIUM |
| `0x000000010000b594` | Set access with prompt | HIGH |
| `0x0000000100047c30` | Reset internal access | MEDIUM |

---

## 8. Next Steps for Implementation

1. **Create DYLD interposer** for `objc_alloc_init` to capture cache creation
2. **Hook SQLite functions** (`sqlite3_step`, `sqlite3_prepare_v2`) to intercept queries
3. **Method swizzle** `-[TCCDServer evaluateComposedAuthorizationToService:...]`
4. **Build cache mirror** to track authorization states without querying database
5. **Implement invalidation strategy** when database is modified externally

---

## References
- Source binary: `/System/Library/PrivateFrameworks/TCC.framework/Support/tccd`
- Disassembly: `LibertyAccessControl/tccdToConvert`
- Converted pseudo-code: `LibertyAccessControl/tccdConverted_Full.c`
