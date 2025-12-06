//
//  CheckPermissionsViewModel.swift
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

class CheckPermissionsViewModel: ObservableObject {
    @Published var permissionStatuses: [String: String] = [:]
    
    func checkAllPermissions() {
        checkAccessibility()
        checkCamera()
        checkMicrophone()
        checkLocation()
        checkContacts()
        checkCalendar()
        checkReminders()
        checkPhotos()
        checkSpeechRecognition()
        checkScreenRecording()
        checkNotifications()
    }
    
    func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        permissionStatuses["Accessibility"] = trusted ? "Authorized" : "Not Authorized"
    }
    
    func checkCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        permissionStatuses["Camera"] = statusString(from: status)
    }
    
    func checkMicrophone() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        permissionStatuses["Microphone"] = statusString(from: status)
    }
    
    func checkLocation() {
        let status = CLLocationManager().authorizationStatus
        permissionStatuses["Location"] = locationStatusString(from: status)
    }
    
    func checkContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        permissionStatuses["Contacts"] = contactsStatusString(from: status)
    }
    
    func checkCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        permissionStatuses["Calendar"] = eventKitStatusString(from: status)
    }
    
    func checkReminders() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        permissionStatuses["Reminders"] = eventKitStatusString(from: status)
    }
    
    func checkPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        permissionStatuses["Photos"] = photoStatusString(from: status)
    }
    
    func checkSpeechRecognition() {
        let status = SFSpeechRecognizer.authorizationStatus()
        permissionStatuses["Speech Recognition"] = speechStatusString(from: status)
    }
    
    func checkScreenRecording() {
        // Note: This will prompt the user if not determined
        // For checking only, we can use CGPreflightScreenCaptureAccess
        let hasAccess = CGPreflightScreenCaptureAccess()
        permissionStatuses["Screen Recording"] = hasAccess ? "Authorized" : "Not Authorized"
    }
    
    func checkNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionStatuses["Notifications"] = self?.notificationStatusString(from: settings.authorizationStatus) ?? "Unknown"
            }
        }
    }
    
    func checkFullDiskAccess() {
        // Full Disk Access can be checked by trying to access a protected location
        // For now, we'll mark it as requiring manual check
        permissionStatuses["Full Disk Access"] = "Check System Preferences"
    }
    
    func checkFilesAndFolders() {
        permissionStatuses["Files and Folders"] = "Check System Preferences"
    }
    
    func checkBluetooth() {
        permissionStatuses["Bluetooth"] = "Requires CBCentralManager"
    }
    
    func checkAppleEvents() {
        permissionStatuses["Apple Events"] = "Check System Preferences"
    }
    
    func checkRemoteFileAccess() {
        permissionStatuses["Allow Remote File Access"] = "Check System Preferences"
    }
    
    func checkRemoteManagement() {
        permissionStatuses["Remote Management"] = "Check System Preferences"
    }
    
    func checkSSH() {
        permissionStatuses["SSH"] = "Check System Preferences"
    }
    
    // Helper methods to convert status enums to strings
    private func statusString(from status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }
    
    private func locationStatusString(from status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }
    
    private func photoStatusString(from status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .limited: return "Limited"
        @unknown default: return "Unknown"
        }
    }
    
    private func notificationStatusString(from status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func contactsStatusString(from status: CNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
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
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }
}
