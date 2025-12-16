//
//  MicrophoneViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import AVFoundation
import Darwin

struct MicrophoneApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class MicrophoneViewModel: ObservableObject {
    @Published var statusMessage: String = "Microphone access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var applications: [MicrophoneApp] = []
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                if granted {
                    self?.statusMessage = "Microphone access granted"
                } else {
                    self?.statusMessage = "Microphone access denied"
                    self?.errorMessage = "User denied microphone access"
                }
            }
        }
    }
    
    func allowAccess() {
        // This would require system-level permissions to modify TCC database
        // For demonstration, we'll show what would happen
        statusMessage = "Allowing microphone access requires system privileges"
        errorMessage = "This requires modifying the TCC database at /Library/Application Support/com.apple.TCC/TCC.db"
    }
    
    func denyAccess() {
        // This would require system-level permissions to modify TCC database
        statusMessage = "Denying microphone access requires system privileges"
        errorMessage = "This requires modifying the TCC database at /Library/Application Support/com.apple.TCC/TCC.db"
    }
    
    func toggleAppAccess(for app: MicrophoneApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        let newAccessState = !applications[index].hasAccess
        
        // Attempt to modify TCC database
        if modifyTCCDatabase(bundleId: app.bundleId, grant: newAccessState) {
            applications[index].hasAccess = newAccessState
            statusMessage = "\(app.name) microphone access \(newAccessState ? "granted" : "denied")"
            errorMessage = nil
        } else {
            errorMessage = "Failed to modify TCC database. Requires root privileges and SIP may need to be disabled."
            statusMessage = "Permission modification failed"
        }
    }
    
    private func modifyTCCDatabase(bundleId: String, grant: Bool) -> Bool {
        // Path to TCC database
        let tccPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        
        // Build SQL command
        let allowed = grant ? 1 : 0
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let sql = """
        INSERT OR REPLACE INTO access 
        (service, client, client_type, auth_value, auth_reason, auth_version, csreq, policy_id, indirect_object_identifier, indirect_object_code_identity, flags, last_modified) 
        VALUES 
        ('kTCCServiceMicrophone', '\(bundleId)', 0, \(allowed), 3, 1, NULL, NULL, NULL, NULL, 0, \(timestamp));
        """
        
        // Try to execute with elevated privileges
        // This requires the app to be run with root or use Authorization Services
        return executeSQLWithPrivileges(database: tccPath, sql: sql)
    }
    
    private func executeSQLWithPrivileges(database: String, sql: String) -> Bool {
        // Create temporary SQL file
        let tempSQL = "/tmp/tcc_modify_\(UUID().uuidString).sql"
        
        // Write SQL to file
        guard let sqlData = sql.data(using: .utf8) else { return false }
        
        // DARWIN: open() syscall - create temporary file
        let fd = open(tempSQL, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        guard fd >= 0 else { return false }
        
        defer {
            // DARWIN: close() syscall
            close(fd)
            // DARWIN: unlink() syscall - delete temp file
            unlink(tempSQL)
        }
        
        // DARWIN: write() syscall - write SQL to file
        _ = sqlData.withUnsafeBytes { bufferPtr in
            write(fd, bufferPtr.baseAddress, sqlData.count)
        }
        
        // Execute sqlite3 with elevated privileges using AuthorizationExecuteWithPrivileges
        // Note: This requires Authorization Services and proper entitlements
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        task.arguments = [database, ".read \(tempSQL)"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Failed to execute sqlite3: \(error)")
            return false
        }
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch authorizationStatus {
        case .authorized:
            statusMessage = "Microphone access authorized"
        case .denied:
            statusMessage = "Microphone access denied"
        case .restricted:
            statusMessage = "Microphone access restricted"
        case .notDetermined:
            statusMessage = "Microphone access not requested"
        @unknown default:
            statusMessage = "Unknown authorization status"
        }
    }
    
    private func loadApplications() {
        // Load common applications that might request microphone access
        // In a real implementation, you'd query the TCC database
        applications = [
            MicrophoneApp(name: "Zoom", bundleId: "us.zoom.xos", hasAccess: false),
            MicrophoneApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
            MicrophoneApp(name: "Chrome", bundleId: "com.google.Chrome", hasAccess: false),
            MicrophoneApp(name: "Discord", bundleId: "com.hnc.Discord", hasAccess: false),
            MicrophoneApp(name: "Slack", bundleId: "com.tinyspeck.slackmacgap", hasAccess: false),
            MicrophoneApp(name: "Microsoft Teams", bundleId: "com.microsoft.teams", hasAccess: false),
            MicrophoneApp(name: "Skype", bundleId: "com.skype.skype", hasAccess: false),
            MicrophoneApp(name: "FaceTime", bundleId: "com.apple.FaceTime", hasAccess: false),
            MicrophoneApp(name: "Voice Memos", bundleId: "com.apple.VoiceMemos", hasAccess: false),
            MicrophoneApp(name: "QuickTime Player", bundleId: "com.apple.QuickTimePlayerX", hasAccess: false)
        ]
    }
}
