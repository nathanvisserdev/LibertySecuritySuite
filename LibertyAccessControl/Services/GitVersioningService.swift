//
//  GitVersioningService.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

struct CommitHashPair: Codable {
    let commitHash: String
    let dbHash: String
    let timestamp: Date
}

enum VerificationMode {
    case usb
    case keychain
    case both // Prefer USB, fallback to keychain
}

class GitVersioningService {
    static let shared = GitVersioningService()
    
    private let dbDirectory: URL
    private let dbFileName = "SecureNotes.encrypted"
    private let usbHashFileName = "LibertyHashes.json"
    private let keychainService = "com.liberty.LibertyAccessControl.commitHashes"
    private let keychainAccount = "commitHashPairs"
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dbDirectory = appSupport.appendingPathComponent("LibertyAccessControl")
        
        // Create directory if needed
        do {
            try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        } catch {
            print("⚠️ Failed to create directory: \(error.localizedDescription)")
        }
        
        // Initialize git repo if needed (safe to call even if git not installed)
        initializeGitRepo()
    }
    
    var dbFileURL: URL {
        dbDirectory.appendingPathComponent(dbFileName)
    }
    
    // MARK: - Git Operations
    
    private func initializeGitRepo() {
        let gitDir = dbDirectory.appendingPathComponent(".git")
        
        // Check if git repo exists
        if !FileManager.default.fileExists(atPath: gitDir.path) {
            // Initialize new git repo
            let result = runGitCommand(["init"], at: dbDirectory)
            if result.success {
                print("✅ Git repository initialized at \(dbDirectory.path)")
                
                // Configure git
                _ = runGitCommand(["config", "user.name", "LibertyAccessControl"], at: dbDirectory)
                _ = runGitCommand(["config", "user.email", "liberty@local"], at: dbDirectory)
            } else {
                print("⚠️ Failed to initialize git repo: \(result.output)")
            }
        }
    }
    
    func commitDatabase(message: String, mode: VerificationMode = .both) -> (success: Bool, commitHash: String?, error: String?) {
        // Add file to git
        var result = runGitCommand(["add", dbFileName], at: dbDirectory)
        guard result.success else {
            return (false, nil, "Failed to stage file: \(result.output)")
        }
        
        // Commit
        result = runGitCommand(["commit", "-m", message], at: dbDirectory)
        guard result.success else {
            return (false, nil, "Failed to commit: \(result.output)")
        }
        
        // Get commit hash
        result = runGitCommand(["rev-parse", "HEAD"], at: dbDirectory)
        guard result.success else {
            return (false, nil, "Failed to get commit hash: \(result.output)")
        }
        
        let commitHash = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Compute database file hash
        guard let dbHash = computeFileHash(dbFileURL) else {
            return (false, nil, "Failed to compute database hash")
        }
        
        // Store based on mode
        var usbStored = false
        var keychainStored = false
        
        switch mode {
        case .usb:
            usbStored = storeHashOnUSB(commitHash: commitHash, dbHash: dbHash)
            if !usbStored {
                return (false, nil, "⚠️ USB drive not found. Please plug in your security USB drive.")
            }
        case .keychain:
            keychainStored = storeHashInKeychain(commitHash: commitHash, dbHash: dbHash)
            if !keychainStored {
                return (false, nil, "Failed to store hash in keychain")
            }
        case .both:
            usbStored = storeHashOnUSB(commitHash: commitHash, dbHash: dbHash)
            keychainStored = storeHashInKeychain(commitHash: commitHash, dbHash: dbHash)
            if !usbStored && !keychainStored {
                return (false, nil, "Failed to store hash in both USB and keychain")
            }
        }
        
        return (true, commitHash, nil)
    }
    
    func verifyIntegrity(mode: VerificationMode = .both) -> (valid: Bool, message: String) {
        var latestPair: CommitHashPair?
        var source = ""
        
        switch mode {
        case .usb:
            guard let usbData = readHashesFromUSB(), let pair = usbData.first else {
                return (false, "⚠️ No verification data found on USB drive")
            }
            latestPair = pair
            source = "USB"
        case .keychain:
            guard let keychainData = readHashesFromKeychain(), let pair = keychainData.first else {
                return (false, "⚠️ No verification data found in keychain")
            }
            latestPair = pair
            source = "Keychain"
        case .both:
            // Try USB first, fallback to keychain
            if let usbData = readHashesFromUSB(), let pair = usbData.first {
                latestPair = pair
                source = "USB"
            } else if let keychainData = readHashesFromKeychain(), let pair = keychainData.first {
                latestPair = pair
                source = "Keychain"
            } else {
                return (false, "⚠️ No verification data found in USB or keychain")
            }
        }
        
        guard let verificationPair = latestPair else {
            return (false, "⚠️ No verification data available")
        }
        
        // Compute current database hash
        guard let currentHash = computeFileHash(dbFileURL) else {
            return (false, "⚠️ Failed to compute current database hash")
        }
        
        // Compare hashes
        if currentHash == verificationPair.dbHash {
            return (true, "✅ Database integrity verified via \(source) (last saved: \(verificationPair.timestamp.formatted()))")
        } else {
            return (false, "🚨 TAMPERING DETECTED! Database has been modified since last commit.\nLast known good commit: \(verificationPair.commitHash)\nVerified via: \(source)")
        }
    }
    
    func restoreToCommit(_ commitHash: String) -> (success: Bool, error: String?) {
        // Checkout specific commit
        let result = runGitCommand(["checkout", commitHash, "--", dbFileName], at: dbDirectory)
        
        if result.success {
            return (true, nil)
        } else {
            return (false, "Failed to restore: \(result.output)")
        }
    }
    
    func getCommitHistory(limit: Int = 10) -> [(hash: String, message: String, date: Date)] {
        let result = runGitCommand(["log", "--pretty=format:%H|%s|%ct", "-n", "\(limit)"], at: dbDirectory)
        
        guard result.success else {
            return []
        }
        
        return result.output.components(separatedBy: "\n")
            .compactMap { line -> (String, String, Date)? in
                let parts = line.components(separatedBy: "|")
                guard parts.count == 3,
                      let timestamp = TimeInterval(parts[2]) else {
                    return nil
                }
                return (parts[0], parts[1], Date(timeIntervalSince1970: timestamp))
            }
    }
    
    func hasUncommittedChanges() -> Bool {
        let result = runGitCommand(["status", "--porcelain"], at: dbDirectory)
        return !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - USB Hash Storage
    
    private func findUSBDrive() -> URL? {
        let fileManager = FileManager.default
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        
        guard let volumes = try? fileManager.contentsOfDirectory(at: volumesURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        // Look for USB drive (not Macintosh HD)
        for volume in volumes {
            let volumeName = volume.lastPathComponent
            if volumeName != "Macintosh HD" && !volumeName.hasPrefix(".") {
                return volume
            }
        }
        
        return nil
    }
    
    private func storeHashOnUSB(commitHash: String, dbHash: String) -> Bool {
        guard let usbDrive = findUSBDrive() else {
            print("⚠️ No USB drive found")
            return false
        }
        
        let hashFileURL = usbDrive.appendingPathComponent(usbHashFileName)
        
        // Read existing hashes
        var hashes = readHashesFromUSB() ?? []
        
        // Add new pair at the beginning (most recent first)
        let newPair = CommitHashPair(commitHash: commitHash, dbHash: dbHash, timestamp: Date())
        hashes.insert(newPair, at: 0)
        
        // Keep only last 100 entries
        if hashes.count > 100 {
            hashes = Array(hashes.prefix(100))
        }
        
        // Write to USB
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(hashes)
            try data.write(to: hashFileURL)
            print("✅ Hash stored on USB: \(usbDrive.lastPathComponent)")
            return true
        } catch {
            print("⚠️ Failed to write hash to USB: \(error.localizedDescription)")
            return false
        }
    }
    
    func readHashesFromUSB() -> [CommitHashPair]? {
        guard let usbDrive = findUSBDrive() else {
            return nil
        }
        
        let hashFileURL = usbDrive.appendingPathComponent(usbHashFileName)
        
        guard let data = try? Data(contentsOf: hashFileURL) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([CommitHashPair].self, from: data)
    }
    
    // MARK: - Keychain Hash Storage
    
    private func storeHashInKeychain(commitHash: String, dbHash: String) -> Bool {
        // Read existing hashes
        var hashes = readHashesFromKeychain() ?? []
        
        // Add new pair at the beginning (most recent first)
        let newPair = CommitHashPair(commitHash: commitHash, dbHash: dbHash, timestamp: Date())
        hashes.insert(newPair, at: 0)
        
        // Keep only last 100 entries
        if hashes.count > 100 {
            hashes = Array(hashes.prefix(100))
        }
        
        // Encode to JSON
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(hashes)
            
            // Create access control for biometric authentication
            var accessControlError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &accessControlError
            ) else {
                print("⚠️ Failed to create access control, storing without biometrics")
                return storeHashInKeychainWithoutBiometrics(data)
            }
            
            let context = LAContext()
            context.localizedReason = "Authenticate to store database verification hash"
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount,
                kSecValueData as String: data,
                kSecAttrAccessControl as String: accessControl,
                kSecUseAuthenticationContext as String: context
            ]
            
            // Delete existing item first
            SecItemDelete(query as CFDictionary)
            
            // Add new item
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess {
                print("✅ Hash stored in keychain with biometric protection")
                return true
            } else {
                print("⚠️ Failed to store in keychain with biometrics (\(status)), trying without")
                return storeHashInKeychainWithoutBiometrics(data)
            }
        } catch {
            print("⚠️ Failed to encode hashes: \(error.localizedDescription)")
            return false
        }
    }
    
    private func storeHashInKeychainWithoutBiometrics(_ data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func readHashesFromKeychain() -> [CommitHashPair]? {
        let context = LAContext()
        context.localizedReason = "Authenticate to access database verification hash"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            // Try without biometrics if the first attempt failed
            return readHashesFromKeychainWithoutBiometrics()
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([CommitHashPair].self, from: data)
    }
    
    private func readHashesFromKeychainWithoutBiometrics() -> [CommitHashPair]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([CommitHashPair].self, from: data)
    }

    
    // MARK: - Hash Computation
    
    private func computeFileHash(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Git Command Execution
    
    private func runGitCommand(_ args: [String], at directory: URL) -> (success: Bool, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = directory
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return (process.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
