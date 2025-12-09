//
//  RequestPermissionsVM.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Combine

class RequestPermissionsVM: ObservableObject {
    @Published var permissionStatuses: [PermissionStatusComparison] = []
    @Published var isLoading: Bool = false
    @Published var statusMessage: String = "Ready to check permissions"
    @Published var errorMessage: String?
    
    private let model: ReqListModel
    
    init(model: ReqListModel = ReqListModel()) {
        self.model = model
    }
    
    /// Load all permission statuses and compare with TCC database
    func loadAllPermissions() {
        isLoading = true
        statusMessage = "Checking all permissions..."
        errorMessage = nil
        
        Task {
            let results = await model.checkAllPermissionsWithComparison()
            
            await MainActor.run {
                self.permissionStatuses = results
                self.isLoading = false
                
                let discrepancyCount = results.filter { $0.hasDiscrepancy }.count
                if discrepancyCount > 0 {
                    self.statusMessage = "⚠️ \(discrepancyCount) permission(s) have discrepancies"
                } else {
                    self.statusMessage = "✓ All permissions match between API and TCC database"
                }
            }
        }
    }
    
    /// Check a specific permission
    func checkPermission(_ permissionType: PermissionType) {
        isLoading = true
        statusMessage = "Checking \(permissionType.rawValue)..."
        errorMessage = nil
        
        Task {
            do {
                let result: PermissionStatusComparison
                
                switch permissionType {
                case .notifications:
                    result = try await model.checkNotificationPermissionWithComparison()
                case .location:
                    result = try await model.checkLocationPermissionWithComparison()
                case .microphone:
                    result = try await model.checkMicrophonePermissionWithComparison()
                case .camera:
                    result = try await model.checkCameraPermissionWithComparison()
                case .screenRecording, .screenSharing:
                    result = try await model.checkScreenRecordingPermissionWithComparison()
                case .fullDiskAccess, .filesAndFolders:
                    result = try await model.checkFullDiskAccessPermissionWithComparison()
                case .accessibility:
                    result = try await model.checkAccessibilityPermissionWithComparison()
                case .photos:
                    result = try await model.checkPhotosPermissionWithComparison()
                case .calendar:
                    result = try await model.checkCalendarPermissionWithComparison()
                case .contacts:
                    result = try await model.checkContactsPermissionWithComparison()
                case .bluetooth:
                    result = await model.checkBluetoothPermissionWithComparison()
                case .reminders:
                    result = try await model.checkRemindersPermissionWithComparison()
                case .appleEvents:
                    // Apple Events doesn't have a comparison method yet
                    throw NSError(domain: "RequestPermissionsVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Apple Events not yet supported"])
                }
                
                await MainActor.run {
                    // Update or add the result
                    if let index = self.permissionStatuses.firstIndex(where: { $0.permissionType == permissionType }) {
                        self.permissionStatuses[index] = result
                    } else {
                        self.permissionStatuses.append(result)
                    }
                    
                    self.isLoading = false
                    self.statusMessage = result.hasDiscrepancy ? 
                        "⚠️ Discrepancy detected in \(permissionType.rawValue)" :
                        "✓ \(permissionType.rawValue) matches"
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Error checking \(permissionType.rawValue)"
                }
            }
        }
    }
    
    /// Request permission for a specific type
    func requestPermission(_ permissionType: PermissionType) {
        isLoading = true
        statusMessage = "Requesting \(permissionType.rawValue)..."
        
        Task {
            do {
                switch permissionType {
                case .notifications:
                    _ = try await model.requestNotificationPermission()
                case .location:
                    _ = try await model.requestLocationPermission()
                case .microphone:
                    _ = try await model.requestMicrophonePermission()
                case .camera:
                    _ = try await model.requestCameraPermission()
                case .screenRecording:
                    _ = try await model.requestScreenRecordingPermission()
                case .fullDiskAccess:
                    _ = try await model.requestFullDiskAccessPermission()
                case .accessibility:
                    _ = try await model.requestAccessibilityPermission()
                case .photos:
                    _ = try await model.requestPhotosPermission()
                case .calendar:
                    _ = try await model.requestCalendarPermission()
                case .contacts:
                    _ = try await model.requestContactsPermission()
                case .bluetooth:
                    _ = await model.requestBluetoothPermission()
                case .reminders:
                    _ = try await model.requestRemindersPermission()
                case .appleEvents:
                    _ = try await model.requestAppleEventsPermission()
                default:
                    break
                }
                
                // After requesting, check the permission again
                checkPermission(permissionType)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Failed to request \(permissionType.rawValue)"
                }
            }
        }
    }
    
    /// Get discrepancies only
    func getDiscrepancies() -> [PermissionStatusComparison] {
        return permissionStatuses.filter { $0.hasDiscrepancy }
    }
    
    /// Get status for a specific permission type
    func getStatus(for permissionType: PermissionType) -> PermissionStatusComparison? {
        return permissionStatuses.first { $0.permissionType == permissionType }
    }
}
