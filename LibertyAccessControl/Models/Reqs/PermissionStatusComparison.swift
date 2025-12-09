//
//  PermissionStatusComparison.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

enum PermissionStatusMatch {
    case matched
    case mismatch(apiStatus: String, tccStatus: String)
    case tccNotFound
    case error(String)
}

struct PermissionStatusComparison: Identifiable {
    let id = UUID()
    let permissionType: PermissionType
    let apiStatus: String
    let systemTCCStatus: String?
    let userTCCStatus: String?
    let matchStatus: PermissionStatusMatch
    
    var hasDiscrepancy: Bool {
        switch matchStatus {
        case .matched:
            return false
        case .mismatch, .tccNotFound, .error:
            return true
        }
    }
    
    var discrepancyDescription: String? {
        switch matchStatus {
        case .matched:
            return nil
        case .mismatch(let apiStatus, let tccStatus):
            return "Mismatch: API shows '\(apiStatus)', TCC shows '\(tccStatus)'"
        case .tccNotFound:
            return "No TCC database entry found"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// TCC Service name mapping
extension PermissionType {
    var tccServiceName: String {
        switch self {
        case .notifications:
            return "kTCCServiceNotifications"
        case .location:
            return "kTCCServiceLocation"
        case .microphone:
            return "kTCCServiceMicrophone"
        case .camera:
            return "kTCCServiceCamera"
        case .screenRecording:
            return "kTCCServiceScreenCapture"
        case .screenSharing:
            return "kTCCServiceScreenCapture"
        case .fullDiskAccess:
            return "kTCCServiceSystemPolicyAllFiles"
        case .accessibility:
            return "kTCCServiceAccessibility"
        case .filesAndFolders:
            return "kTCCServiceSystemPolicyAllFiles"
        case .photos:
            return "kTCCServicePhotos"
        case .calendar:
            return "kTCCServiceCalendar"
        case .contacts:
            return "kTCCServiceAddressBook"
        case .bluetooth:
            return "kTCCServiceBluetooth"
        case .reminders:
            return "kTCCServiceReminders"
        case .appleEvents:
            return "kTCCServiceAppleEvents"
        }
    }
}
