//
//  ScreenRecordingViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import ScreenCaptureKit

struct ScreenRecordingApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class ScreenRecordingViewModel: ObservableObject {
    @Published var statusMessage: String = "Screen recording access not requested"
    @Published var errorMessage: String?
    @Published var applications: [ScreenRecordingApp] = []
    
    init() {
        loadApplications()
        checkPermission()
    }
    
    func requestAccess() {
        Task { @MainActor in
            do {
                // Try to get shareable content - this will trigger permission prompt
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                if !content.displays.isEmpty {
                    statusMessage = "Screen recording access granted"
                    errorMessage = nil
                } else {
                    statusMessage = "Screen recording access checking..."
                }
            } catch {
                statusMessage = "Screen recording access denied or restricted"
                errorMessage = "Please enable Screen Recording in System Settings > Privacy & Security"
            }
        }
    }
    
    func toggleAppAccess(for app: ScreenRecordingApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) screen recording access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func checkPermission() {
        // Screen recording doesn't have a simple status check, so we show a generic message
        statusMessage = "Click 'Request Access' to check screen recording permission"
    }
    
    private func loadApplications() {
        applications = [
            ScreenRecordingApp(name: "QuickTime Player", bundleId: "com.apple.QuickTimePlayerX", hasAccess: true),
            ScreenRecordingApp(name: "Zoom", bundleId: "us.zoom.xos", hasAccess: true),
            ScreenRecordingApp(name: "OBS Studio", bundleId: "com.obsproject.obs-studio", hasAccess: true),
            ScreenRecordingApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
        ]
    }
}
