//
//  ReqListViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Combine

@MainActor
class ReqListViewModel: ObservableObject {
    @Published var model = ReqListModel()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Business logic for requesting permissions
    func requestPermission(for type: PermissionType) {
        Task {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            
            defer {
                isLoading = false
            }
            
            do {
                let request: PermissionRequest
                
                switch type {
                case .notifications:
                    request = try await model.requestNotificationPermission()
                case .location:
                    request = try await model.requestLocationPermission()
                case .microphone:
                    request = try await model.requestMicrophonePermission()
                case .camera:
                    request = try await model.requestCameraPermission()
                case .screenRecording:
                    request = try await model.requestScreenRecordingPermission()
                case .screenSharing:
                    request = try await model.requestScreenSharingPermission()
                case .fullDiskAccess:
                    request = try await model.requestFullDiskAccessPermission()
                case .accessibility:
                    request = try await model.requestAccessibilityPermission()
                case .filesAndFolders:
                    request = try await model.requestFilesAndFoldersPermission()
                case .photos:
                    request = try await model.requestPhotosPermission()
                case .calendar:
                    request = try await model.requestCalendarPermission()
                case .contacts:
                    request = try await model.requestContactsPermission()
                case .bluetooth:
                    request = await model.requestBluetoothPermission()
                case .reminders:
                    request = try await model.requestRemindersPermission()
                case .appleEvents:
                    request = try await model.requestAppleEventsPermission()
                }
                
                // Update UI based on result
                if request.granted {
                    successMessage = request.message
                } else {
                    errorMessage = request.message
                }
                
            } catch {
                errorMessage = "Failed to request \(type.rawValue) permission: \(error.localizedDescription)"
            }
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // Filter request history by type
    func getHistory(for type: PermissionType) -> [PermissionRequest] {
        model.requestHistory.filter { $0.type == type }
    }
    
    // Get all request history sorted by timestamp
    func getAllHistory() -> [PermissionRequest] {
        model.requestHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    // Clear request history
    func clearHistory() {
        model.requestHistory.removeAll()
        successMessage = "Request history cleared"
    }
}
