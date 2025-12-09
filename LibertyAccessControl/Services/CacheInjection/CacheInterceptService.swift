//
//  CacheInterceptService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import Foundation

class CacheInterceptService {
    
    static let shared = CacheInterceptService()
    
    private lazy var hookDylibPath: String = {
        return "/Users/nathanvisser/Code/test/LibertyAccessControl/LibertyAccessControl/Services/CacheInjection/tccd_hook.dylib"
    }()
    
    // Use secure app container for logs
    private lazy var logPath: String = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let secureDir = appSupport.appendingPathComponent("LibertyAccessControl/TCCHooks")
        try? FileManager.default.createDirectory(at: secureDir, withIntermediateDirectories: true)
        return secureDir.appendingPathComponent("tccd_hook.log").path
    }()
    
    private lazy var cacheSnapshotPath: String = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let secureDir = appSupport.appendingPathComponent("LibertyAccessControl/TCCHooks")
        try? FileManager.default.createDirectory(at: secureDir, withIntermediateDirectories: true)
        return secureDir.appendingPathComponent("tccd_cache_snapshot.json").path
    }()
    
    private init() {
        // Empty - dylib path is lazy loaded
    }
    
    /// Kill tccd and restart it with cache interception
    func restartTCCDWithInterception(targetBundleId: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Step 1: Kill existing tccd
                let killMsg = "🔴 Killing tccd..."
                print(killMsg)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SystemLogMessage"),
                        object: nil,
                        userInfo: ["message": killMsg, "type": SystemMessage.MessageType.info]
                    )
                }
                try self.killTCCD()
                
                // Step 2: Wait a moment for cleanup
                usleep(500000) // 0.5 seconds
                
                // Step 3: Start tccd with our hook injected
                let startMsg = "🟢 Starting tccd with hook..."
                print(startMsg)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SystemLogMessage"),
                        object: nil,
                        userInfo: ["message": startMsg, "type": SystemMessage.MessageType.info]
                    )
                }
                try self.startTCCDWithHook(targetBundleId: targetBundleId)
                
                // Step 4: Wait for cache to be captured
                usleep(1000000) // 1 second
                
                // Step 5: Read the log to get cache info
                let cacheInfo = try self.readCacheInfo()
                
                DispatchQueue.main.async {
                    completion(.success(cacheInfo))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Kill all tccd processes
    private func killTCCD() throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        task.arguments = ["tccd"]
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            print("⚠️ tccd may not have been running")
        }
    }
    
    /// Start tccd with dylib injection
    private func startTCCDWithHook(targetBundleId: String?) throws {
        // Check if dylib exists
        guard FileManager.default.fileExists(atPath: hookDylibPath) else {
            print("⚠️ dylib not found at: \(hookDylibPath)")
            print("⚠️ Skipping cache interception - dylib needs to be copied to app bundle")
            throw NSError(domain: "CacheIntercept", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "tccd_hook.dylib not found in app bundle. Build it first: cd Services/CacheInjection && ./build_and_inject.sh"
            ])
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/TCC.framework/Support/tccd")
        
        var env = ProcessInfo.processInfo.environment
        env["DYLD_INSERT_LIBRARIES"] = hookDylibPath
        env["TCCD_HOOK_LOG_PATH"] = logPath
        
        if let target = targetBundleId {
            env["TCCD_REVOKE_TARGET"] = target
        }
        
        task.environment = env
        task.arguments = []
        
        // Run in background
        try task.run()
        
        // Don't wait - let it run in background
        let successMsg = "✅ tccd started with hook injected"
        print(successMsg)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SystemLogMessage"),
                object: nil,
                userInfo: ["message": successMsg, "type": SystemMessage.MessageType.success]
            )
        }
    }
    
    /// Read cache information from the hook log
    private func readCacheInfo() throws -> String {
        guard FileManager.default.fileExists(atPath: logPath) else {
            throw NSError(domain: "CacheIntercept", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Hook log not found. Make sure tccd_hook.dylib is built and in Resources."
            ])
        }
        
        let logContents = try String(contentsOfFile: logPath, encoding: .utf8)
        
        // Parse out cache information
        var cacheInfo = "=== Cache Interception Results ===\n\n"
        
        // Look for cache allocation
        if let allocationLine = logContents.components(separatedBy: "\n")
            .first(where: { $0.contains("Captured AdhocSignatureCache") }) {
            cacheInfo += "✓ \(allocationLine)\n"
        }
        
        // Look for cache name
        if let nameLine = logContents.components(separatedBy: "\n")
            .first(where: { $0.contains("Cache name:") }) {
            cacheInfo += "✓ \(nameLine)\n"
        }
        
        // Look for NSCache object
        if let nsCacheLine = logContents.components(separatedBy: "\n")
            .first(where: { $0.contains("NSCache object captured") }) {
            cacheInfo += "✓ \(nsCacheLine)\n"
        }
        
        // Look for revocation action
        if let revokeLine = logContents.components(separatedBy: "\n")
            .first(where: { $0.contains("Removed") && $0.contains("from signature cache") }) {
            cacheInfo += "✓ \(revokeLine)\n"
        }
        
        // Save snapshot
        try self.saveCacheSnapshot(logContents: logContents)
        
        return cacheInfo
    }
    
    /// Save a snapshot of the cache state
    private func saveCacheSnapshot(logContents: String) throws {
        let snapshot: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "log": logContents,
            "status": "captured"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: snapshot, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: cacheSnapshotPath))
        
        let snapshotMsg = "💾 Cache snapshot saved to \(cacheSnapshotPath)"
        print(snapshotMsg)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SystemLogMessage"),
                object: nil,
                userInfo: ["message": snapshotMsg, "type": SystemMessage.MessageType.success]
            )
        }
    }
    
    /// Get the latest cache snapshot
    func getCacheSnapshot() -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: cacheSnapshotPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: cacheSnapshotPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    /// Clear the hook log
    func clearLog() {
        try? "".write(toFile: logPath, atomically: true, encoding: .utf8)
    }
}
