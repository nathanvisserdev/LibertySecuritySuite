//
//  GitVersioningService.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import Foundation
import CryptoKit

struct CommitHashPair: Codable {
    let commitHash: String
    let dbHash: String
    let timestamp: Date
}

class GitVersioningService {
    static let shared = GitVersioningService()
    
    private let dbDirectory: URL
    private let dbFileName = "SecureNotes.encrypted"
    private let usbHashFileName = "LibertyHashes.json"
    
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
    
    func commitDatabase(message: String) -> (success: Bool, commitHash: String?, error: String?) {
        // Check if USB is available
        guard findUSBDrive() != nil else {
            return (false, nil, "⚠️ USB drive not found. Please plug in your security USB drive to save.")
        }
        
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
        
        // Store commit-hash pair on USB
        let stored = storeHashOnUSB(commitHash: commitHash, dbHash: dbHash)
        if !stored {
            print("⚠️ Warning: Failed to store hash on USB drive")
        }
        
        return (true, commitHash, nil)
    }
    
    func verifyIntegrity() -> (valid: Bool, message: String) {
        // Check if USB is available
        guard findUSBDrive() != nil else {
            return (false, "⚠️ USB drive not found. Plug in USB to verify integrity.")
        }
        
        // Get latest commit from USB
        guard let usbData = readHashesFromUSB(),
              let latestPair = usbData.first else {
            return (false, "⚠️ No verification data found on USB drive")
        }
        
        // Compute current database hash
        guard let currentHash = computeFileHash(dbFileURL) else {
            return (false, "⚠️ Failed to compute current database hash")
        }
        
        // Compare hashes
        if currentHash == latestPair.dbHash {
            return (true, "✅ Database integrity verified (last saved: \(latestPair.timestamp.formatted()))")
        } else {
            return (false, "🚨 TAMPERING DETECTED! Database has been modified since last commit.\nLast known good commit: \(latestPair.commitHash)")
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
