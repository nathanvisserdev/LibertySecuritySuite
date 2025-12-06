//
//  FullDiskAccessViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import AppKit

struct FullDiskAccessApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class FullDiskAccessViewModel: ObservableObject {
    @Published var statusMessage: String = "Full Disk Access not verified"
    @Published var errorMessage: String?
    @Published var hasAccess: Bool = false
    @Published var applications: [FullDiskAccessApp] = []
    
    init() {
        loadApplications()
        checkAccess()
    }
    
    func requestAccess() {
        // Trigger an access attempt to get the app added to FDA list
        // This will fail without FDA, but macOS will add the app to the list
        let protectedPaths = [
            "/Library/Application Support/com.apple.TCC/TCC.db",
            NSHomeDirectory() + "/Library/Safari/History.db",
            "/Library/Application Support/com.apple.TCC/"
        ]
        
        // Attempt to access protected files to trigger FDA prompt/listing
        for path in protectedPaths {
            _ = FileManager.default.fileExists(atPath: path)
            _ = try? FileManager.default.contentsOfDirectory(atPath: path)
            _ = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        
        // Now check if we actually have access
        checkAccess()
        
        if !hasAccess {
            statusMessage = "Full Disk Access denied - Opening System Settings..."
            errorMessage = "This app should now appear in System Settings > Privacy & Security > Full Disk Access. Enable it and restart the app."
            
            // Open System Settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
            
            // Fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            statusMessage = "Full Disk Access already granted"
            errorMessage = nil
        }
    }
    
    func toggleAppAccess(for app: FullDiskAccessApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) Full Disk Access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func checkAccess() {
        // Try to read Calendars directory - requires FDA
        let calendarsPath = NSHomeDirectory() + "/Library/Calendars"
        
        // Attempt to read the directory - this will fail without FDA
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: calendarsPath)
            hasAccess = true
            statusMessage = "Full Disk Access granted"
            errorMessage = nil
        } catch {
            hasAccess = false
            statusMessage = "Full Disk Access not granted"
            errorMessage = "Click 'Request Access' to open System Settings"
        }
    }
    
    private func loadApplications() {
        applications = [
            FullDiskAccessApp(name: "Terminal", bundleId: "com.apple.Terminal", hasAccess: true),
            FullDiskAccessApp(name: "Finder", bundleId: "com.apple.finder", hasAccess: true),
            FullDiskAccessApp(name: "Time Machine", bundleId: "com.apple.backup.launcher", hasAccess: true),
            FullDiskAccessApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
        ]
    }
}
