/*
 * tccd_decompiled.c
 * Auto-generated C pseudo-code from tccd binary disassembly
 * 
 * IMPORTANT: This file identifies hook points for TCC interception
 * Use these addresses with DYLD_INSERT_LIBRARIES or Frida
 */

#include <Foundation/Foundation.h>
#include <dispatch/dispatch.h>

// ============================================================================
// KEY HOOK POINTS FOR TCC INTERCEPTION
// ============================================================================

/*
 * CRITICAL FUNCTIONS TO HOOK:
 *
 * Address: 000000010000189c
 *   Context: Auth:{Invalid}
 *
 * Address: 0000000100007e64
 *   Context: do_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath
 *
 * Address: 00000001000090bc
 *   Name: handle_TCCCheckIfDatabaseIsRegistered
 *   Context: dbPath
 *
 * Address: 000000010000ab24
 *   Context: TCC_MSG_REQUEST_AUTHORIZATION_SUBJECT_CREDENTIAL_DICTIONARY_KEY
 *
 * Address: 000000010000b594
 *   Name: handle_TCCSetAccessWithPrompt
 *   Context: handle_TCCSetAccessWithPrompt
 *
 * Address: 000000010001a030
 *   Context: INSERT OR REPLACE INTO access   (service, client, client_type, auth_value, auth_
 *
 * Address: 000000010001d258
 *   Context: Error retrieving authorization record associated with attribution chain: %@ serv
 *
 * Address: 0000000100027070
 *   Context: CREATE TABLE IF NOT EXISTS NEW_access (    service        TEXT        NOT NULL, 
 *
 * Address: 000000010002d208
 *   Context: target_token
 *
 * Address: 00000001000358b0
 *   Name: -[TCCDServer evaluateComposedAuthorizationToService:andAccessSubject:withRelation:authorizationResult:authorizationReason:subjectCodeIdentityDataResult:]
 *   Context: -[TCCDServer evaluateComposedAuthorizationToService:andAccessSubject:withRelatio
 *
 * Address: 0000000100035930
 *   Context: -[TCCDServer numberOfRecordsForService:withAuthorizationValue:]
 *
 * Address: 0000000100035da0
 *   Context: prompt type is upgrade but received a auth result of deny: %@
 *
 * Address: 0000000100036138
 *   Context: event_type
 *
 * Address: 0000000100047c30
 *   Name: handle_TCCAccessResetInternal_with_attribution_chain
 *   Context: handle_TCCAccessResetInternal_with_attribution_chain
 *
 * Address: 0000000100047ccc
 *   Name: handle_TCCAccessCopyInformation_with_attribution_chain
 *   Context: handle_TCCAccessCopyInformation_with_attribution_chain
 *
 * Address: 0000000100047d28
 *   Name: handle_TCCAccessCopyInformation_with_attribution_chain
 *   Context: handle_TCCAccessCopyInformation_with_attribution_chain
 *
 * Address: 0000000100047d9c
 *   Name: handle_TCCAccessCopyInformation_with_attribution_chain_block_invoke
 *   Context: handle_TCCAccessCopyInformation_with_attribution_chain_block_invoke
 *
 * Address: 0000000100047e1c
 *   Name: handle_TCCAccessCopyInformation(): skipping identity type: IDENTITY_TYPE_POLICY_ID for identifier: %{public}s.
 *   Context: handle_TCCAccessCopyInformation(): skipping identity type: IDENTITY_TYPE_POLICY_
 *
 * Address: 0000000100047eac
 *   Name: handle_TCCAccessCopyInformation(): failed to find an Application URL for bundle ID: %{public}@.
 *   Context: handle_TCCAccessCopyInformation(): failed to find an Application URL for bundle 
 *
 * Address: 0000000100047f20
 *   Name: handle_TCCAccessCopyInformation(): Unknown identity type: %d.
 *   Context: handle_TCCAccessCopyInformation(): Unknown identity type: %d.
 *
 */

// ============================================================================
// FUNCTION PSEUDO-CODE
// ============================================================================

// Address: 0x000000010000189c
void* tccd_function_000000010000189c() {
    // Start: 0x000000010000189c
    // Context strings:
    //   "Auth:{Invalid}"
    //   "Unknown Access Type!"
    //   "Allowed"
    //   "Denied"
    //   "{Access:%s, reason:%s}"
    // Instructions: 38
    //
    // Key operations:
    //   00000001000018b4: tbnz	x0, #0x38, 0x1000018c4
}

// Address: 0x0000000100007e64
void* tccd_function_0000000100007e64() {
    // Start: 0x0000000100007e64
    // Context strings:
    //   "do_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath"
    //   "%s: processing incoming request"
    // Instructions: 213
    //
    // Key operations:
}

// Address: 0x00000001000090bc
void* handle_TCCCheckIfDatabaseIsRegistered() {
    // Start: 0x00000001000090bc
    // Context strings:
    //   "dbPath"
    //   "handle_TCCCheckIfDatabaseIsRegistered"
    //   "%{public}s: %{public}s"
    // Instructions: 118
    //
    // Key operations:
}

// Address: 0x000000010000ab24
void* tccd_function_000000010000ab24() {
    // Start: 0x000000010000ab24
    // Context strings:
    //   "TCC_MSG_REQUEST_AUTHORIZATION_SUBJECT_CREDENTIAL_DICTIONARY_KEY"
    // Instructions: 254
    //
    // Key operations:
    //   000000010000ab44: bl	0x100062fd4 ; symbol stub for: _objc_retain
}

// Address: 0x000000010000b594
void* handle_TCCSetAccessWithPrompt() {
    // Start: 0x000000010000b594
    // Context strings:
    //   "handle_TCCSetAccessWithPrompt"
    //   "%s begin"
    // Instructions: 877
    //
    // Key operations:
}

// Address: 0x000000010001a030
void* tccd_function_000000010001a030() {
    // Start: 0x000000010001a030
    // Context strings:
    //   "INSERT OR REPLACE INTO access   (service, client, client_type, auth_value, auth_reason, auth_version, csreq, policy_id, indirect_object_identifier_type, indirect_object_identifier, indirect_object_code_identity) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    // Instructions: 49
    //
    // Key operations:
    //   000000010001a050: ldr	x16, [x16, #0xbf0] ; literal pool symbol address: __NSCo
}

// Address: 0x000000010001d258
void* tccd_function_000000010001d258() {
    // Start: 0x000000010001d258
    // Context strings:
    //   "Error retrieving authorization record associated with attribution chain: %@ service: %@"
    // Instructions: 27
    //
    // Key operations:
}

// Address: 0x0000000100027070
void* tccd_function_0000000100027070() {
    // Start: 0x0000000100027070
    // Context strings:
    //   "CREATE TABLE IF NOT EXISTS NEW_access (    service        TEXT        NOT NULL,     client         TEXT        NOT NULL,     client_type    INTEGER     NOT NULL,     auth_value     INTEGER     NOT NULL,     auth_reason    INTEGER     NOT NULL,     auth_version   INTEGER     NOT NULL,     csreq          BLOB,     policy_id      INTEGER,     indirect_object_identifier_type    INTEGER,     indirect_object_identifier         TEXT NOT NULL DEFAULT 'UNUSED',     indirect_object_code_identity      BLOB,     flags          INTEGER,     last_modified  INTEGER     NOT NULL DEFAULT (CAST(strftime('%s','now') AS INTEGER)),     PRIMARY KEY (service, client, client_type, indirect_object_identifier),    FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE ON UPDATE CASCADE)"
    //   "SELECT * FROM access"
    //   "DROP TABLE access"
    //   "ALTER TABLE NEW_access RENAME TO access"
    // Instructions: 48
    //
    // Key operations:
}

// Address: 0x000000010002d208
void* tccd_function_000000010002d208() {
    // Start: 0x000000010002d208
    // Context strings:
    //   "target_token"
    //   "indirect_object_token"
    //   "TCCD_MSG_CREDENTIAL_AUTHENTICATOR_AUDIT_TOKEN_KEY"
    //   "target_csreq"
    //   "extension"
    // Instructions: 191
    //
    // Key operations:
}

// Address: 0x00000001000358b0
void* __TCCDServer_evaluateComposedAuthorizationToService_andAccessSubject_withRelation_authorizationResult_authorizationReason_subjectCodeIdentityDataResult__() {
    // Start: 0x00000001000358b0
    // Context strings:
    //   "-[TCCDServer evaluateComposedAuthorizationToService:andAccessSubject:withRelation:authorizationResult:authorizationReason:subjectCodeIdentityDataResult:]"
    //   "%{public}s: %{public}@"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x0000000100035930
void* tccd_function_0000000100035930() {
    // Start: 0x0000000100035930
    // Context strings:
    //   "-[TCCDServer numberOfRecordsForService:withAuthorizationValue:]"
    //   "%{public}s: database access error for: %{public}@"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x0000000100035da0
void* tccd_function_0000000100035da0() {
    // Start: 0x0000000100035da0
    // Context strings:
    //   "prompt type is upgrade but received a auth result of deny: %@"
    // Instructions: 45
    //
    // Key operations:
}

// Address: 0x0000000100036138
void* tccd_function_0000000100036138() {
    // Start: 0x0000000100036138
    // Context strings:
    //   "event_type"
    //   "service"
    //   "TCCD_MSG_IDENTITY_TYPE_KEY"
    //   "TCCD_MSG_IDENTITY_ID_KEY"
    //   "auth_value"
    // Instructions: 55
    //
    // Key operations:
}

// Address: 0x0000000100047c30
void* handle_TCCAccessResetInternal_with_attribution_chain() {
    // Start: 0x0000000100047c30
    // Context strings:
    //   "handle_TCCAccessResetInternal_with_attribution_chain"
    //   "%{public}s: %{public}@"
    // Instructions: 29
    //
    // Key operations:
}

// Address: 0x0000000100047ccc
void* handle_TCCAccessCopyInformation_with_attribution_chain() {
    // Start: 0x0000000100047ccc
    // Context strings:
    //   "handle_TCCAccessCopyInformation_with_attribution_chain"
    //   "%{public}s: returning %zu clients"
    // Instructions: 23
    //
    // Key operations:
}

// Address: 0x0000000100047d28
void* handle_TCCAccessCopyInformation_with_attribution_chain() {
    // Start: 0x0000000100047d28
    // Context strings:
    //   "handle_TCCAccessCopyInformation_with_attribution_chain"
    //   "%{public}s: %{public}@"
    // Instructions: 29
    //
    // Key operations:
}

// Address: 0x0000000100047d9c
void* handle_TCCAccessCopyInformation_with_attribution_chain_block_invoke() {
    // Start: 0x0000000100047d9c
    // Context strings:
    //   "handle_TCCAccessCopyInformation_with_attribution_chain_block_invoke"
    //   "%s: OSSystemExtensionClient is not available"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x0000000100047e1c
void* handle_TCCAccessCopyInformation__skipping_identity_type__IDENTITY_TYPE_POLICY_ID_for_identifier____public_s_() {
    // Start: 0x0000000100047e1c
    // Context strings:
    //   "handle_TCCAccessCopyInformation(): skipping identity type: IDENTITY_TYPE_POLICY_ID for identifier: %{public}s."
    // Instructions: 36
    //
    // Key operations:
}

// Address: 0x0000000100047eac
void* handle_TCCAccessCopyInformation__failed_to_find_an_Application_URL_for_bundle_ID____public___() {
    // Start: 0x0000000100047eac
    // Context strings:
    //   "handle_TCCAccessCopyInformation(): failed to find an Application URL for bundle ID: %{public}@."
    // Instructions: 29
    //
    // Key operations:
}

// Address: 0x0000000100047f20
void* handle_TCCAccessCopyInformation__Unknown_identity_type___d_() {
    // Start: 0x0000000100047f20
    // Context strings:
    //   "handle_TCCAccessCopyInformation(): Unknown identity type: %d."
    // Instructions: 36
    //
    // Key operations:
}

// Address: 0x0000000100047fb0
void* handle_TCCAccessCopyInformation__failed_to_allocate_clientInfo_dictionary_() {
    // Start: 0x0000000100047fb0
    // Context strings:
    //   "handle_TCCAccessCopyInformation(): failed to allocate clientInfo dictionary."
    // Instructions: 16
    //
    // Key operations:
}

// Address: 0x0000000100048218
void* handle_TCCCreateDesignatedRequirementIdentityFromAuditTokenForService() {
    // Start: 0x0000000100048218
    // Context strings:
    //   "handle_TCCCreateDesignatedRequirementIdentityFromAuditTokenForService"
    //   "%{public}s: %{public}@"
    // Instructions: 29
    //
    // Key operations:
}

// Address: 0x000000010004828c
void* tccd_function_000000010004828c() {
    // Start: 0x000000010004828c
    // Context strings:
    //   "do_TCCCreateDesignatedRequirementIdentityFromAuditTokenForService"
    //   "%s: no audit token provided."
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x000000010004830c
void* handle_TCCAccessCopyBundleIdentifiersForService_with_attribution_chain() {
    // Start: 0x000000010004830c
    // Context strings:
    //   "handle_TCCAccessCopyBundleIdentifiersForService_with_attribution_chain"
    //   "%{public}s: %{public}@"
    // Instructions: 29
    //
    // Key operations:
}

// Address: 0x0000000100048380
void* handle_TCCAccessCopyInformationForBundle_with_attribution_chain_block_invoke_2() {
    // Start: 0x0000000100048380
    // Context strings:
    //   "handle_TCCAccessCopyInformationForBundle_with_attribution_chain_block_invoke_2"
    //   "%s: failed to allocate accessRecord dictionary"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x0000000100048400
void* handle_TCCAccessCopyBundleIdentifiersDisabledForService_with_attribution_chain() {
    // Start: 0x0000000100048400
    // Context strings:
    //   "handle_TCCAccessCopyBundleIdentifiersDisabledForService_with_attribution_chain"
    //   "%{public}s: %{public}@"
    // Instructions: 29
    //
    // Key operations:
}

// Address: 0x000000010004c64c
void* tccd_function_000000010004c64c() {
    // Start: 0x000000010004c64c
    // Context strings:
    //   "_locked_populatePolicyAuthorizationsForService(): failed to allocate recordInfo dictionary."
    // Instructions: 17
    //
    // Key operations:
}

// Address: 0x000000010004fabc
void* tccd_function_000000010004fabc() {
    // Start: 0x000000010004fabc
    // Context strings:
    //   "-[TCCDPlatform sendAnalyticsForAction:service:subjectIdentity:indirectObjectIdentity:authValue:includeV1AuthValue:v1AuthValue:desiredAuth:domainReason:promptType:macBuddyStatus:]_block_invoke"
    //   "%s: Analytics is not available for Event: %{public}@"
    // Instructions: 30
    //
    // Key operations:
}

// Address: 0x000000010004fc24
void* tccd_function_000000010004fc24() {
    // Start: 0x000000010004fc24
    // Context strings:
    //   "result"
    //   "auth_value"
    //   "auth_reason"
    //   "auth_error_string"
    //   "auth_error_code"
    // Instructions: 59
    //
    // Key operations:
    //   000000010004fc40: bl	0x100062fd4 ; symbol stub for: _objc_retain
}

// Address: 0x00000001000500c0
void* tccd_function_00000001000500c0() {
    // Start: 0x00000001000500c0
    // Context strings:
    //   "preflight_unknown"
    //   "result"
    //   "restricted"
    //   "do_not_cache"
    //   "auth_value"
    // Instructions: 339
    //
    // Key operations:
    //   00000001000500dc: bl	0x100062fd4 ; symbol stub for: _objc_retain
}

// Address: 0x0000000100052f00
void* TCCAccessResetInternal() {
    // Start: 0x0000000100052f00
    // Context strings:
    //   "function"
    //   "TCCAccessResetInternal"
    //   "TCCAccessCopyInformation"
    // Instructions: 441
    //
    // Key operations:
}

// Address: 0x00000001000536cc
void* tccd_function_00000001000536cc() {
    // Start: 0x00000001000536cc
    // Context strings:
    //   "com.apple.universalaccessAuthWarn"
    // Instructions: 279
    //
    // Key operations:
}

// Address: 0x0000000100057c9c
void* tccd_function_0000000100057c9c() {
    // Start: 0x0000000100057c9c
    // Context strings:
    //   "codeRequirementFromStaticCode:%p SecStaticCodeCheckValidity() fails: %ld"
    // Instructions: 28
    //
    // Key operations:
}

// Address: 0x000000010005bd4c
void* tccd_function_000000010005bd4c() {
    // Start: 0x000000010005bd4c
    // Context strings:
    //   "Skipping MDM policy authorization record with invalid IdentifierType: %{public}@"
    // Instructions: 30
    //
    // Key operations:
}

// Address: 0x000000010005c428
void* tccd_function_000000010005c428() {
    // Start: 0x000000010005c428
    // Context strings:
    //   "%{public}@ failed entitlement check"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x000000010005c4a4
void* tccd_function_000000010005c4a4() {
    // Start: 0x000000010005c4a4
    // Context strings:
    //   "%{public}@ passed entitlement check"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x000000010005f544
void* tccd_function_000000010005f544() {
    // Start: 0x000000010005f544
    // Context strings:
    //   "Failed to check if we've already set up the registry, starting unconditionally"
    // Instructions: 16
    //
    // Key operations:
}

// Address: 0x000000010005fe90
void* handle_TCCAccessSetInternal() {
    // Start: 0x000000010005fe90
    // Context strings:
    //   "handle_TCCAccessSetInternal"
    //   "%{public}s: %{public}@"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x000000010005ff0c
void* tccd_function_000000010005ff0c() {
    // Start: 0x000000010005ff0c
    // Context strings:
    //   "Failed to check database registry string"
    // Instructions: 18
    //
    // Key operations:
}

// Address: 0x0000000100060474
void* handle_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath() {
    // Start: 0x0000000100060474
    // Context strings:
    //   "handle_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath"
    //   "%{public}s: %{public}@"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x00000001000604f0
void* tccd_function_00000001000604f0() {
    // Start: 0x00000001000604f0
    // Context strings:
    //   "do_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath"
    //   "%s: providerDomainForURL error: %@"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x000000010006056c
void* tccd_function_000000010006056c() {
    // Start: 0x000000010006056c
    // Context strings:
    //   "do_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath"
    //   "%s: FPProviderDomain is not available"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x00000001000605ec
void* tccd_function_00000001000605ec() {
    // Start: 0x00000001000605ec
    // Context strings:
    //   "do_TCCCreateIndirectObjectIdentityForFileProviderDomainFromPath"
    //   "%s: no path provided"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x000000010006066c
void* handle_TCCAccessSetOverride() {
    // Start: 0x000000010006066c
    // Context strings:
    //   "handle_TCCAccessSetOverride"
    //   "%{public}s: %{public}@"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x00000001000606e8
void* handle_TCCAccessGetOverride() {
    // Start: 0x00000001000606e8
    // Context strings:
    //   "handle_TCCAccessGetOverride"
    //   "%{public}s: %{public}@"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x00000001000607d4
void* handle_TCCAccessSetPidResponsibleForPid() {
    // Start: 0x00000001000607d4
    // Context strings:
    //   "handle_TCCAccessSetPidResponsibleForPid"
    //   "%{public}s: %{public}@"
    // Instructions: 31
    //
    // Key operations:
}

// Address: 0x0000000100060850
void* handle_TCCCheckIfDatabaseIsRegistered() {
    // Start: 0x0000000100060850
    // Context strings:
    //   "handle_TCCCheckIfDatabaseIsRegistered"
    //   "%{public}s should only be done by the system tccd"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x00000001000608d0
void* tccd_function_00000001000608d0() {
    // Start: 0x00000001000608d0
    // Context strings:
    //   "Failed to check if known db"
    // Instructions: 15
    //
    // Key operations:
}

// Address: 0x000000010006090c
void* handle_TCCCheckIfDatabaseIsRegistered() {
    // Start: 0x000000010006090c
    // Context strings:
    //   "handle_TCCCheckIfDatabaseIsRegistered"
    //   "%{public}s: got a null dbPath??"
    // Instructions: 32
    //
    // Key operations:
}

// Address: 0x000000010006098c
void* handle_TCCRegisterNewDatabase() {
    // Start: 0x000000010006098c
    // Context strings:
    //   "handle_TCCRegisterNewDatabase"
    //   "%{public}s should only be done by the system tccd"
    // Instructions: 32
    //
    // Key operations:
}


// ============================================================================
// HOOK TEMPLATE (for use with DYLD_INSERT_LIBRARIES)
// ============================================================================

/*
 * Example hook using function interposition:
 *
 * #include <dlfcn.h>
 *
 * typedef void* (*original_func_t)(void*, void*, void*);
 *
 * void* hooked_TCCAccessRequest(void* arg1, void* arg2, void* arg3) {
 *     NSLog(@"[HOOK] TCCAccessRequest called!");
 *     
 *     // Call original
 *     original_func_t original = dlsym(RTLD_NEXT, "TCCAccessRequest");
 *     void* result = original(arg1, arg2, arg3);
 *     
 *     NSLog(@"[HOOK] Result: %@", result);
 *     return result;
 * }
 *
 * // Interpose
 * __attribute__((used)) static struct {
 *     const void* replacement;
 *     const void* replacee;
 * } TCCAccessRequest_interpose 
 *     __attribute__((section("__DATA,__interpose"))) = {
 *     (const void*)(unsigned long)&hooked_TCCAccessRequest,
 *     (const void*)(unsigned long)&TCCAccessRequest
 * };
 */

// ============================================================================
// IMPORTANT ADDRESSES FOR MANUAL HOOKING (Frida/LLDB)
// ============================================================================

/*
 * Use these addresses with Frida:
 *
 * Interceptor.attach(Module.findBaseAddress('tccd').add(0x<ADDRESS>), {
 *     onEnter: function(args) {
 *         console.log('[+] Function called');
 *     },
 *     onLeave: function(retval) {
 *         console.log('[+] Returned:', retval);
 *     }
 * });
 */

/*
 * ALL FUNCTION ADDRESSES:
 * 0x000000010000189c: unnamed
 * 0x0000000100001934: unnamed
 * 0x00000001000019bc: unnamed
 * 0x0000000100001a58: unnamed
 * 0x0000000100001ba4: unnamed
 * 0x0000000100001d9c: unnamed
 * 0x0000000100001f1c: unnamed
 * 0x00000001000020cc: unnamed
 * 0x0000000100002134: unnamed
 * 0x0000000100002184: unnamed
 * 0x0000000100002a1c: unnamed
 * 0x0000000100002d40: unnamed
 * 0x0000000100002ea4: unnamed
 * 0x0000000100002f70: unnamed
 * 0x0000000100003024: unnamed
 * 0x00000001000031e4: unnamed
 * 0x0000000100003328: unnamed
 * 0x00000001000034a8: unnamed
 * 0x000000010000350c: unnamed
 * 0x000000010000365c: unnamed
 * 0x00000001000037a8: unnamed
 * 0x0000000100003804: unnamed
 * 0x0000000100003840: unnamed
 * 0x000000010000387c: unnamed
 * 0x0000000100003c14: unnamed
 * 0x0000000100003c48: unnamed
 * 0x0000000100003d5c: unnamed
 * 0x0000000100003de0: unnamed
 * 0x0000000100003e38: unnamed
 * 0x0000000100003e80: unnamed
 * 0x0000000100003fe8: unnamed
 * 0x0000000100004020: unnamed
 * 0x0000000100004180: unnamed
 * 0x00000001000041b8: unnamed
 * 0x00000001000041f4: unnamed
 * 0x0000000100004284: unnamed
 * 0x0000000100004330: unnamed
 * 0x0000000100004478: unnamed
 * 0x0000000100004498: unnamed
 * 0x000000010000457c: unnamed
 * 0x000000010000470c: unnamed
 * 0x0000000100004784: unnamed
 * 0x00000001000047d4: unnamed
 * 0x0000000100004818: unnamed
 * 0x00000001000048b8: unnamed
 * 0x00000001000049b8: unnamed
 * 0x0000000100004a28: unnamed
 * 0x0000000100004a90: unnamed
 * 0x0000000100004b74: unnamed
 * 0x0000000100005278: unnamed
 * 0x00000001000052f8: unnamed
 * 0x0000000100005404: unnamed
 * 0x0000000100005450: unnamed
 * 0x00000001000054f4: unnamed
 * 0x000000010000558c: unnamed
 * 0x00000001000058bc: unnamed
 * 0x0000000100006100: unnamed
 * 0x000000010000624c: unnamed
 * 0x00000001000066a8: unnamed
 * 0x000000010000674c: unnamed
 * 0x0000000100007e64: unnamed
 * 0x00000001000081b8: unnamed
 * 0x0000000100008398: unnamed
 * 0x0000000100008564: unnamed
 * 0x0000000100008684: unnamed
 * 0x000000010000894c: unnamed
 * 0x0000000100008c50: unnamed
 * 0x0000000100008ecc: unnamed
 * 0x00000001000090bc: handle_TCCCheckIfDatabaseIsRegistered
 * 0x0000000100009294: unnamed
 * 0x00000001000093a8: unnamed
 * 0x00000001000096a8: unnamed
 * 0x0000000100009b54: unnamed
 * 0x0000000100009e20: unnamed
 * 0x000000010000ab24: unnamed
 * 0x000000010000af1c: unnamed
 * 0x000000010000b594: handle_TCCSetAccessWithPrompt
 * 0x000000010000c348: unnamed
 * 0x000000010000c480: unnamed
 * 0x000000010000c960: unnamed
 * 0x00000001000142ec: unnamed
 * 0x00000001000143ac: unnamed
 * 0x00000001000148ac: unnamed
 * 0x0000000100014ac8: unnamed
 * 0x0000000100014b48: unnamed
 * 0x0000000100014bb4: unnamed
 * 0x0000000100014cd4: unnamed
 * 0x0000000100014e50: unnamed
 * 0x0000000100015c04: unnamed
 * 0x0000000100019494: unnamed
 * 0x000000010001959c: unnamed
 * 0x00000001000195ec: unnamed
 * 0x0000000100019630: unnamed
 * 0x00000001000199f4: unnamed
 * 0x0000000100019a74: unnamed
 * 0x0000000100019adc: unnamed
 * 0x0000000100019b40: unnamed
 * 0x0000000100019b68: unnamed
 * 0x000000010001a030: unnamed
 * 0x000000010001a0f4: unnamed
 */
