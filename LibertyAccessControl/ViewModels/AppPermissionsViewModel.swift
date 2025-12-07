//
//  AppPermissionsViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import CoreLocation
import Contacts
import EventKit
import Photos
import Speech
import UserNotifications
import ApplicationServices

struct AppPermissionsViewModel {
    var permissionStatuses: [String: String] = [:]
    let systemTCCDBService: SystemTCCDBService
    
    mutating func checkAllPermissions() {
        checkAccessibility()
        checkAppManagement()
        checkCamera()
        checkMicrophone()
        checkLocation()
        checkContacts()
        checkPhotos()
        checkSpeechRecognition()
        checkScreenRecording()
        // Note: checkCalendar(), checkReminders(), and checkNotifications() must be called separately with completion handlers
    }
    
    mutating func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        permissionStatuses["Accessibility"] = trusted ? "AXI Authorization Status: Authorized" : "AXI Authorization Status: Not Authorized"
    }
    
    mutating func checkCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        permissionStatuses["Camera"] = statusString(from: status)
    }
    
    func requestCameraPermission(completion: @escaping (String) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            let statusString = self.statusString(from: status)
            DispatchQueue.main.async {
                completion(statusString)
            }
        }
    }
    
    mutating func checkMicrophone() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        permissionStatuses["Microphone"] = statusString(from: status)
    }
    
    func requestMicrophonePermission(completion: @escaping (String) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            let statusString = self.statusString(from: status)
            DispatchQueue.main.async {
                completion(statusString)
            }
        }
    }
    
    mutating func checkLocation() {
        let status = CLLocationManager().authorizationStatus
        permissionStatuses["Location"] = locationStatusString(from: status)
    }
    
    mutating func checkContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        permissionStatuses["Contacts"] = contactsStatusString(from: status)
    }
    
    func requestContactsPermission(completion: @escaping (String) -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            let status = CNContactStore.authorizationStatus(for: .contacts)
            let statusString = self.contactsStatusString(from: status)
            DispatchQueue.main.async {
                completion(statusString)
            }
        }
    }
    
    func checkCalendar(completion: @escaping (String) -> Void) {
        if #available(macOS 14.0, *) {
            let store = EKEventStore()
            Task {
                do {
                    let granted = try await store.requestFullAccessToEvents()
                    let status = granted ? "Authorized" : "Denied"
                    DispatchQueue.main.async {
                        completion(status)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion("Error: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            completion(eventKitStatusString(from: status))
        }
    }
    
    func checkReminders(completion: @escaping (String) -> Void) {
        if #available(macOS 14.0, *) {
            let store = EKEventStore()
            Task {
                do {
                    let granted = try await store.requestFullAccessToReminders()
                    let status = granted ? "Authorized" : "Denied"
                    DispatchQueue.main.async {
                        completion(status)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion("Error: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let status = EKEventStore.authorizationStatus(for: .reminder)
            completion(eventKitStatusString(from: status))
        }
    }
    
    mutating func checkPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        permissionStatuses["Photos"] = photoStatusString(from: status)
    }
    
    func requestPhotosPermission(completion: @escaping (String) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            let statusString = self.photoStatusString(from: status)
            DispatchQueue.main.async {
                completion(statusString)
            }
        }
    }
    
    mutating func checkSpeechRecognition() {
        let status = SFSpeechRecognizer.authorizationStatus()
        permissionStatuses["Speech Recognition"] = speechStatusString(from: status)
    }
    
    func requestSpeechRecognitionPermission(completion: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            let statusString = self.speechStatusString(from: status)
            DispatchQueue.main.async {
                completion(statusString)
            }
        }
    }
    
    mutating func checkScreenRecording() {
        // Note: This will prompt the user if not determined
        // For checking only, we can use CGPreflightScreenCaptureAccess
        let hasAccess = CGPreflightScreenCaptureAccess()
        permissionStatuses["Screen Recording"] = hasAccess ? "CG Authorization Status: Authorized" : "CG Authorization Status: Not Authorized"
    }
    
    func requestScreenRecordingPermission(completion: @escaping (String) -> Void) {
        // CGRequestScreenCaptureAccess will prompt the user for screen recording permission
        let hasAccess = CGRequestScreenCaptureAccess()
        let statusString = hasAccess ? "CG Authorization Status: Authorized" : "CG Authorization Status: Not Authorized"
        DispatchQueue.main.async {
            completion(statusString)
        }
    }
    
    func checkNotifications(completion: @escaping (String) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = self.notificationStatusString(from: settings.authorizationStatus)
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    mutating func checkFullDiskAccess() {
        // Full Disk Access can be checked by trying to access a protected location
        // For now, we'll mark it as requiring manual check
        permissionStatuses["Full Disk Access"] = "Check System Preferences"
    }
    
    mutating func checkFilesAndFolders() {
        permissionStatuses["Files and Folders"] = "Check System Preferences"
    }
    
    mutating func checkBluetooth() {
        permissionStatuses["Bluetooth"] = "Requires CBCentralManager"
    }
    
    mutating func checkAppleEvents() {
        permissionStatuses["Apple Events"] = "Check System Preferences"
    }
    
    mutating func checkAppManagement() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            permissionStatuses["App Management"] = "Unable to determine bundle ID"
            return
        }
        
        print("Bundle ID:", bundleIdentifier)
        
        if let entry = systemTCCDBService.queryEntry(service: "kTCCServiceSystemPolicyAppBundles", client: bundleIdentifier) {
            // auth_value: 0 = denied, 2 = allowed
            let status = entry.auth_value == 2 ? "Authorized" : "Denied"
            permissionStatuses["App Management"] = status
        } else {
            permissionStatuses["App Management"] = "TCC Authorization Status: Entry Not Found"
        }
    }
    
    func requestAppManagementPermission(completion: @escaping (String) -> Void) {
        // App Management permissions can't be requested programmatically like Camera/Microphone
        // We need to open System Preferences to the Privacy & Security pane
        // The user must manually grant access there
        
        // First, try to trigger the prompt by using the Service Management framework
        if #available(macOS 13.0, *) {
            // On macOS 13+, try to use SMAppService to trigger a prompt
            // This typically only works for login items, but we can try
            DispatchQueue.main.async {
                let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AppManagement"
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                    completion("Opening System Preferences - Please grant App Management permission manually")
                } else {
                    completion("Unable to open System Preferences")
                }
            }
        } else {
            // On older macOS versions, open the Security & Privacy preference pane
            DispatchQueue.main.async {
                let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_SystemPolicyAppBundles"
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                    completion("Opening System Preferences - Please grant App Management permission manually")
                } else {
                    completion("Unable to open System Preferences")
                }
            }
        }
    }
    
    mutating func checkRemoteFileAccess() {
        permissionStatuses["Allow Remote File Access"] = "Check System Preferences"
    }
    
    mutating func checkRemoteManagement() {
        permissionStatuses["Remote Management"] = "Check System Preferences"
    }
    
    mutating func checkSSH() {
        permissionStatuses["SSH"] = "Check System Preferences"
    }
    
    // Helper methods to convert status enums to strings
    private func statusString(from status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "AV Authorization Status: Authorized"
        case .denied: return "AV Authorization Status: Denied"
        case .notDetermined: return "AV Authorization Status: Not yet requested"
        case .restricted: return "AV Authorization Status: Restricted"
        @unknown default: return "AV Authorization Status: Unknown"
        }
    }
    
    private func locationStatusString(from status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "CL Authorization Status: Authorized Always"
        case .authorizedWhenInUse: return "CL Authorization Status: Authorized When In Use"
        case .denied: return "CL Authorization Status: Denied"
        case .notDetermined: return "CL Authorization Status: Not Determined"
        case .restricted: return "CL Authorization Status: Restricted"
        @unknown default: return "CL Authorization Status: Unknown"
        }
    }
    
    private func photoStatusString(from status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "PH Authorization Status: Authorized"
        case .denied: return "PH Authorization Status: Denied"
        case .notDetermined: return "PH Authorization Status: Not Determined"
        case .restricted: return "PH Authorization Status: Restricted"
        case .limited: return "PH Authorization Status: Limited"
        @unknown default: return "PH Authorization Status: Unknown"
        }
    }
    
    private func notificationStatusString(from status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "UN Authorization Status: Authorized"
        case .denied: return "UN Authorization Status: Denied"
        case .notDetermined: return "UN Authorization Status: Not Determined"
        case .provisional: return "UN Authorization Status: Provisional"
        case .ephemeral: return "UN Authorization Status: Ephemeral"
        @unknown default: return "UN Authorization Status: Unknown"
        }
    }
    
    private func contactsStatusString(from status: CNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "CN Authorization Status: Authorized"
        case .denied: return "CN Authorization Status: Denied"
        case .notDetermined: return "CN Authorization Status: Not Determined"
        case .restricted: return "CN Authorization Status: Restricted"
        @unknown default: return "CN Authorization Status: Unknown"
        }
    }
    
    private func eventKitStatusString(from status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .writeOnly: return "Write Only"
        case .fullAccess: return "Full Access"
        @unknown default: return "Unknown"
        }
    }
    
    private func speechStatusString(from status: SFSpeechRecognizerAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "SF Authorization Status: Authorized"
        case .denied: return "SF Authorization Status: Denied"
        case .notDetermined: return "SF Authorization Status: Not Determined"
        case .restricted: return "SF Authorization Status: Restricted"
        @unknown default: return "SF Authorization Status: Unknown"
        }
    }
}
