//
//  TCCCacheReader.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Darwin.Mach

class TCCCacheReader {
    static let shared = TCCCacheReader()
    
    private var capturedCache: [String: [String: Any]] = [:]
    private var cacheCapturePath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let secureDir = appSupport.appendingPathComponent("LibertyAccessControl/TCCCache")
        try? FileManager.default.createDirectory(at: secureDir, withIntermediateDirectories: true)
        return secureDir.appendingPathComponent("tcc_cache_capture.json").path
    }
    
    private init() {}
    
    /// Capture the entire TCC cache by reading tccd's memory
    func captureCache(completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Step 1: Kill existing tccd to force a clean restart
                let killMsg = "🔴 Killing tccd daemon..."
                print(killMsg)
                self.postMessage(killMsg, type: .info)
                
                try self.killTCCD()
                
                let killedMsg = "✅ tccd daemon killed successfully"
                print(killedMsg)
                self.postMessage(killedMsg, type: .success)
                
                // Step 2: Wait for tccd to restart (macOS will auto-restart it)
                let waitMsg = "⏳ Waiting for tccd to restart..."
                print(waitMsg)
                self.postMessage(waitMsg, type: .info)
                
                usleep(1000000) // 1 second - give it time to restart
                
                // Step 3: Find the restarted tccd process
                let findMsg = "🔍 Looking for restarted tccd process..."
                print(findMsg)
                self.postMessage(findMsg, type: .info)
                
                var tccdPID: pid_t?
                var attempts = 0
                let maxAttempts = 10
                
                // Poll for tccd process (it should restart automatically)
                while tccdPID == nil && attempts < maxAttempts {
                    tccdPID = self.findTCCDProcess()
                    if tccdPID == nil {
                        usleep(500000) // Wait 0.5 seconds between attempts
                        attempts += 1
                    }
                }
                
                guard let pid = tccdPID else {
                    throw TCCCacheError.processNotFound
                }
                
                let foundMsg = "✅ Found tccd process: PID \(pid)"
                print(foundMsg)
                self.postMessage(foundMsg, type: .success)
                
                // Step 4: Hook into the process memory
                let hookMsg = "🪝 Hooking into tccd memory (requires root + SIP disabled)..."
                print(hookMsg)
                self.postMessage(hookMsg, type: .info)
                
                // Get task port for tccd
                var task: mach_port_name_t = 0
                let kr = task_for_pid(mach_task_self_, pid, &task)
                
                guard kr == KERN_SUCCESS else {
                    throw TCCCacheError.taskAccessDenied(code: kr)
                }
                
                let taskMsg = "✅ Successfully hooked into tccd memory space"
                print(taskMsg)
                self.postMessage(taskMsg, type: .success)
                
                // Step 5: Scan memory for cache data
                let scanMsg = "🔬 Scanning tccd memory for TCC cache entries..."
                print(scanMsg)
                self.postMessage(scanMsg, type: .info)
                
                let cacheData = try self.scanMemoryForCache(task: task)
                
                // Step 6: Save the captured cache
                try self.saveCapturedCache(cacheData)
                
                let summary = """
                === TCC Cache Capture Summary ===
                • Process ID: \(pid)
                • Captured entries: \(cacheData.count)
                • Saved to: \(self.cacheCapturePath)
                """
                
                DispatchQueue.main.async {
                    completion(.success(summary))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Find the tccd process ID
    private func findTCCDProcess() -> pid_t? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["tccd"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let pid = Int32(output) {
                return pid
            }
        } catch {
            print("Error finding tccd: \(error)")
        }
        
        return nil
    }
    
    /// Kill the tccd daemon
    private func killTCCD() throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        task.arguments = ["killall", "tccd"]
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let warnMsg = "⚠️ tccd may not have been running (or killall failed)"
            print(warnMsg)
            self.postMessage(warnMsg, type: .warning)
        }
    }
    
    /// Scan tccd memory for cache structures
    private func scanMemoryForCache(task: mach_port_name_t) throws -> [String: [String: Any]] {
        var cacheEntries: [String: [String: Any]] = [:]
        
        var address: mach_vm_address_t = 0
        var size: mach_vm_size_t = 0
        var info = vm_region_basic_info_data_64_t()
        var infoCount = mach_msg_type_number_t(MemoryLayout<vm_region_basic_info_data_64_t>.size / MemoryLayout<natural_t>.size)
        var objectName: mach_port_t = 0
        
        let scanMsg = "🔬 Scanning tccd memory regions for cache data..."
        print(scanMsg)
        self.postMessage(scanMsg, type: .info)
        
        var regionsScanned = 0
        var heapRegionsFound = 0
        
        // Iterate through memory regions
        while true {
            var kr = withUnsafeMutablePointer(to: &info) { infoPtr in
                infoPtr.withMemoryRebound(to: integer_t.self, capacity: 1) { intPtr in
                    mach_vm_region(task, &address, &size, VM_REGION_BASIC_INFO_64, intPtr, &infoCount, &objectName)
                }
            }
            
            if kr != KERN_SUCCESS {
                break
            }
            
            regionsScanned += 1
            
            // Look for readable/writable heap regions where cache would live
            if (info.protection & VM_PROT_READ) != 0 && (info.protection & VM_PROT_WRITE) != 0 {
                heapRegionsFound += 1
                
                // Read this memory region
                if let data = self.readMemoryRegion(task: task, address: address, size: min(size, 1024 * 1024)) { // Limit to 1MB per region
                    // Search for TCC-related strings and patterns
                    self.extractCacheEntriesFromData(data, into: &cacheEntries)
                }
            }
            
            address += size
        }
        
        let scanSummary = "📊 Scanned \(regionsScanned) regions, found \(heapRegionsFound) heap regions, extracted \(cacheEntries.count) cache entries"
        print(scanSummary)
        self.postMessage(scanSummary, type: .info)
        
        return cacheEntries
    }
    
    /// Read a memory region from the target task
    private func readMemoryRegion(task: mach_port_name_t, address: mach_vm_address_t, size: mach_vm_size_t) -> Data? {
        var data: vm_offset_t = 0
        var dataCount: mach_msg_type_number_t = 0
        
        let kr = mach_vm_read(task, address, size, &data, &dataCount)
        
        guard kr == KERN_SUCCESS else {
            return nil
        }
        
        let buffer = UnsafeRawBufferPointer(start: UnsafeRawPointer(bitPattern: UInt(data)), count: Int(dataCount))
        return Data(buffer)
    }
    
    /// Extract TCC cache entries from memory data
    private func extractCacheEntriesFromData(_ data: Data, into cacheEntries: inout [String: [String: Any]]) {
        // Convert data to string to search for bundle IDs and service names
        guard let memoryString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return
        }
        
        // Common TCC service patterns
        let servicePatterns = [
            "kTCCServiceCamera",
            "kTCCServiceMicrophone",
            "kTCCServiceScreenCapture",
            "kTCCServiceAccessibility",
            "kTCCServiceSystemPolicyAllFiles",
            "kTCCServicePhotos",
            "kTCCServiceCalendar",
            "kTCCServiceContacts",
            "kTCCServiceReminders",
            "kTCCServiceUbiquity",
            "kTCCServiceLocation",
            "kTCCServiceBluetoothAlways"
        ]
        
        // Bundle ID pattern (com.*, org.*, etc.)
        let bundleIDPattern = try? NSRegularExpression(pattern: "(com|org|net|io)\\.[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+", options: [])
        
        // Find service names
        for service in servicePatterns {
            if memoryString.contains(service) {
                // Try to find associated bundle IDs nearby
                if let regex = bundleIDPattern {
                    let matches = regex.matches(in: memoryString, range: NSRange(memoryString.startIndex..., in: memoryString))
                    for match in matches {
                        if let range = Range(match.range, in: memoryString) {
                            let bundleID = String(memoryString[range])
                            let key = "\(service):\(bundleID)"
                            cacheEntries[key] = [
                                "service": service,
                                "client": bundleID,
                                "found_in_memory": true,
                                "timestamp": Date().timeIntervalSince1970
                            ]
                        }
                    }
                }
            }
        }
    }
    
    /// Save captured cache to disk
    private func saveCapturedCache(_ cache: [String: [String: Any]]) throws {
        capturedCache = cache
        
        let cacheData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "entries": cache,
            "count": cache.count,
            "version": "1.0"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: cacheData, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: cacheCapturePath))
        
        let saveMsg = "💾 Cache snapshot saved to \(cacheCapturePath)"
        print(saveMsg)
        self.postMessage(saveMsg, type: .success)
    }
    
    /// Get captured cache entries
    func getCapturedCache() -> [String: [String: Any]]? {
        guard !capturedCache.isEmpty else {
            let errorMsg = "⚠️ TCC cache is empty - capture may have failed or not been performed yet"
            print(errorMsg)
            self.postMessage(errorMsg, type: .warning)
            return nil
        }
        return capturedCache
    }
    
    /// Load previously saved cache
    func loadSavedCache() -> [String: [String: Any]]? {
        guard FileManager.default.fileExists(atPath: cacheCapturePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: cacheCapturePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["entries"] as? [String: [String: Any]] else {
            return nil
        }
        
        capturedCache = entries
        return entries
    }
    
    /// Post message to system log
    private func postMessage(_ message: String, type: SystemMessage.MessageType) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SystemLogMessage"),
                object: nil,
                userInfo: ["message": message, "type": type]
            )
        }
    }
    
    /// Revoke permission by invalidating cache entry
    func revokePermission(service: String, client: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Kill tccd to force cache invalidation
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
                task.arguments = ["killall", "tccd"]
                
                try task.run()
                task.waitUntilExit()
                
                let msg = "✅ tccd killed - cache invalidated. Permission for \(client) will be re-evaluated."
                print(msg)
                self.postMessage(msg, type: .success)
                
                // Wait for tccd to restart
                usleep(500000) // 0.5 seconds
                
                DispatchQueue.main.async {
                    completion(.success(msg))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Errors
enum TCCCacheError: LocalizedError {
    case processNotFound
    case taskAccessDenied(code: kern_return_t)
    case memoryReadFailed
    
    var errorDescription: String? {
        switch self {
        case .processNotFound:
            return "tccd process not found. Is it running?"
        case .taskAccessDenied(let code):
            return "Cannot access tccd memory (kern_return: \(code)). Requires root privileges and SIP disabled."
        case .memoryReadFailed:
            return "Failed to read tccd memory regions"
        }
    }
}
