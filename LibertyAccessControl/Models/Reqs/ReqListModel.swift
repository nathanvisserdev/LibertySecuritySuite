//
//  ReqListModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import UserNotifications
import CoreLocation
import AVFoundation
import Photos
import EventKit
import Contacts

class ReqListModel {
    let notificationService: UNReq
    let locationService: LocReqServ
    let microphoneService: MicReqServ
    let cameraService: CamReqServ
    let screenRecordingService: SRReqServ
    let screenSharingService: SSReqServ
    let fullDiskAccessService: FDAReqServ
    let accessibilityService: AccReqServ
    let filesAndFoldersService: FFReqServ
    let photosService: PhReqServ
    let calendarService: CalReqServ
    let contactsService: ContReqServ
    let bluetoothService: BTReqServ
    let remindersService: RemReqServ
    let appleEventsService: AEReqServ
    
    let systemService: SystemService
    let userService: UserService
    let appBundleID: String
    
    init(
        notificationService: UNReq = UNReq(),
        locationService: LocReqServ = LocReqServ(),
        microphoneService: MicReqServ = MicReqServ(),
        cameraService: CamReqServ = CamReqServ(),
        screenRecordingService: SRReqServ = SRReqServ(),
        screenSharingService: SSReqServ = SSReqServ(),
        fullDiskAccessService: FDAReqServ = FDAReqServ(),
        accessibilityService: AccReqServ = AccReqServ(),
        filesAndFoldersService: FFReqServ = FFReqServ(),
        photosService: PhReqServ = PhReqServ(),
        calendarService: CalReqServ = CalReqServ(),
        contactsService: ContReqServ = ContReqServ(),
        bluetoothService: BTReqServ = BTReqServ(),
        remindersService: RemReqServ = RemReqServ(),
        appleEventsService: AEReqServ = AEReqServ(),
        systemService: SystemService = SystemService(),
        userService: UserService = UserService(),
        appBundleID: String = Bundle.main.bundleIdentifier ?? "com.libertyaccesscontrol.LibertyAccessControl"
    ) {
        self.notificationService = notificationService
        self.locationService = locationService
        self.microphoneService = microphoneService
        self.cameraService = cameraService
        self.screenRecordingService = screenRecordingService
        self.screenSharingService = screenSharingService
        self.fullDiskAccessService = fullDiskAccessService
        self.accessibilityService = accessibilityService
        self.filesAndFoldersService = filesAndFoldersService
        self.photosService = photosService
        self.calendarService = calendarService
        self.contactsService = contactsService
        self.bluetoothService = bluetoothService
        self.remindersService = remindersService
        self.appleEventsService = appleEventsService
        self.systemService = systemService
        self.userService = userService
        self.appBundleID = appBundleID
    }

    func requestNotificationPermission() async throws -> UNAuthStatDTO {
        let status = try await notificationService.reqPerm()
        let dto = UNAuthStatDTO(from: status)
        return dto
    }
    
    func requestLocationPermission() async throws -> CLAuthStatDTO {
        let status = try await locationService.reqPerm()
        let dto = CLAuthStatDTO(from: status)
        return dto
    }
    
    func requestMicrophonePermission() async throws -> AVAuthStatDTO {
        let status = try await microphoneService.reqPerm()
        let dto = AVAuthStatDTO(from: status)
        return dto
    }
    
    func requestCameraPermission() async throws -> AVAuthStatDTO {
        let status = try await cameraService.reqPerm()
        let dto = AVAuthStatDTO(from: status)
        return dto
    }
    
    func requestScreenRecordingPermission() async throws -> BoolAuthDTO {
        let granted = try await screenRecordingService.reqPerm()
        let dto = BoolAuthDTO(from: granted)
        return dto
    }
    
    func requestScreenSharingPermission() async throws -> BoolAuthDTO {
        let granted = try await screenSharingService.reqPerm()
        let dto = BoolAuthDTO(from: granted)
        return dto
    }
    
    func requestFullDiskAccessPermission() async throws -> BoolAuthDTO {
        let granted = try await fullDiskAccessService.reqPerm()
        let dto = BoolAuthDTO(from: granted)
        return dto
    }
    
    func requestAccessibilityPermission() async throws -> BoolAuthDTO {
        let granted = try await accessibilityService.reqPerm()
        let dto = BoolAuthDTO(from: granted)
        return dto
    }
    
    func requestFilesAndFoldersPermission() async throws -> BoolAuthDTO {
        let granted = try await filesAndFoldersService.reqPerm()
        let dto = BoolAuthDTO(from: granted)
        return dto
    }
    
    func requestPhotosPermission() async throws -> PHAuthStatDTO {
        let status = try await photosService.reqPerm()
        let dto = PHAuthStatDTO(from: status)
        return dto
    }
    
    func requestCalendarPermission() async throws -> EKAuthStatDTO {
        let status = try await calendarService.reqPerm()
        let dto = EKAuthStatDTO(from: status)
        return dto
    }
    
    func requestContactsPermission() async throws -> CNAuthStatDTO {
        let status = try await contactsService.reqPerm()
        let dto = CNAuthStatDTO(from: status)
        return dto
    }
    
    func requestBluetoothPermission() async -> BoolAuthDTO {
        let granted = await bluetoothService.reqPerm()
        let dto = BoolAuthDTO(from: granted)
        return dto
    }
    
    func requestRemindersPermission() async throws -> EKAuthStatDTO {
        let status = try await remindersService.reqPerm()
        let dto = EKAuthStatDTO(from: status)
        return dto
    }
    
    func requestAppleEventsPermission() async throws -> OSStatus {
        let status = try await appleEventsService.reqPerm()
        return status
    }
    
    // MARK: - Permission Status Comparison Methods
    
    /// Check notification permission and compare with TCC database
    func checkNotificationPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestNotificationPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.notifications.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .notifications,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check location permission and compare with TCC database
    func checkLocationPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestLocationPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.location.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .location,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check microphone permission and compare with TCC database
    func checkMicrophonePermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestMicrophonePermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.microphone.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .microphone,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check camera permission and compare with TCC database
    func checkCameraPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestCameraPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.camera.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .camera,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check screen recording permission and compare with TCC database
    func checkScreenRecordingPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestScreenRecordingPermission()
        let apiStatus = dto.granted ? "Granted" : "Denied"
        
        let tccServiceName = PermissionType.screenRecording.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .screenRecording,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check full disk access permission and compare with TCC database
    func checkFullDiskAccessPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestFullDiskAccessPermission()
        let apiStatus = dto.granted ? "Granted" : "Denied"
        
        let tccServiceName = PermissionType.fullDiskAccess.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .fullDiskAccess,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check accessibility permission and compare with TCC database
    func checkAccessibilityPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestAccessibilityPermission()
        let apiStatus = dto.granted ? "Granted" : "Denied"
        
        let tccServiceName = PermissionType.accessibility.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .accessibility,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check photos permission and compare with TCC database
    func checkPhotosPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestPhotosPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.photos.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .photos,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check calendar permission and compare with TCC database
    func checkCalendarPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestCalendarPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.calendar.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .calendar,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check contacts permission and compare with TCC database
    func checkContactsPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestContactsPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.contacts.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .contacts,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check bluetooth permission and compare with TCC database
    func checkBluetoothPermissionWithComparison() async -> PermissionStatusComparison {
        let dto = await requestBluetoothPermission()
        let apiStatus = dto.granted ? "Granted" : "Denied"
        
        let tccServiceName = PermissionType.bluetooth.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .bluetooth,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check reminders permission and compare with TCC database
    func checkRemindersPermissionWithComparison() async throws -> PermissionStatusComparison {
        let dto = try await requestRemindersPermission()
        let apiStatus = statusToString(dto.status)
        
        let tccServiceName = PermissionType.reminders.tccServiceName
        let systemTCC = systemService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        let userTCC = userService.getAuthValue(service: tccServiceName, clientBundleID: appBundleID)
        
        return createComparison(
            permissionType: .reminders,
            apiStatus: apiStatus,
            systemAuthValue: systemTCC,
            userAuthValue: userTCC
        )
    }
    
    /// Check all permissions and return comparison results
    func checkAllPermissionsWithComparison() async -> [PermissionStatusComparison] {
        var results: [PermissionStatusComparison] = []
        
        // Try each permission, catching errors individually
        do {
            let notification = try await checkNotificationPermissionWithComparison()
            results.append(notification)
        } catch {
            results.append(errorComparison(for: .notifications, error: error))
        }
        
        do {
            let location = try await checkLocationPermissionWithComparison()
            results.append(location)
        } catch {
            results.append(errorComparison(for: .location, error: error))
        }
        
        do {
            let microphone = try await checkMicrophonePermissionWithComparison()
            results.append(microphone)
        } catch {
            results.append(errorComparison(for: .microphone, error: error))
        }
        
        do {
            let camera = try await checkCameraPermissionWithComparison()
            results.append(camera)
        } catch {
            results.append(errorComparison(for: .camera, error: error))
        }
        
        do {
            let screenRecording = try await checkScreenRecordingPermissionWithComparison()
            results.append(screenRecording)
        } catch {
            results.append(errorComparison(for: .screenRecording, error: error))
        }
        
        do {
            let fullDisk = try await checkFullDiskAccessPermissionWithComparison()
            results.append(fullDisk)
        } catch {
            results.append(errorComparison(for: .fullDiskAccess, error: error))
        }
        
        do {
            let accessibility = try await checkAccessibilityPermissionWithComparison()
            results.append(accessibility)
        } catch {
            results.append(errorComparison(for: .accessibility, error: error))
        }
        
        do {
            let photos = try await checkPhotosPermissionWithComparison()
            results.append(photos)
        } catch {
            results.append(errorComparison(for: .photos, error: error))
        }
        
        do {
            let calendar = try await checkCalendarPermissionWithComparison()
            results.append(calendar)
        } catch {
            results.append(errorComparison(for: .calendar, error: error))
        }
        
        do {
            let contacts = try await checkContactsPermissionWithComparison()
            results.append(contacts)
        } catch {
            results.append(errorComparison(for: .contacts, error: error))
        }
        
        let bluetooth = await checkBluetoothPermissionWithComparison()
        results.append(bluetooth)
        
        do {
            let reminders = try await checkRemindersPermissionWithComparison()
            results.append(reminders)
        } catch {
            results.append(errorComparison(for: .reminders, error: error))
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    private func createComparison(
        permissionType: PermissionType,
        apiStatus: String,
        systemAuthValue: Int?,
        userAuthValue: Int?
    ) -> PermissionStatusComparison {
        let systemTCCStatus = authValueToString(systemAuthValue)
        let userTCCStatus = authValueToString(userAuthValue)
        
        // Determine primary TCC status (user TCC takes precedence)
        let primaryTCCStatus = userTCCStatus ?? systemTCCStatus
        
        // Check for match
        let matchStatus: PermissionStatusMatch
        if let tccStatus = primaryTCCStatus {
            // Compare API status with TCC status
            if statusesMatch(apiStatus: apiStatus, tccStatus: tccStatus) {
                matchStatus = .matched
            } else {
                matchStatus = .mismatch(apiStatus: apiStatus, tccStatus: tccStatus)
            }
        } else {
            matchStatus = .tccNotFound
        }
        
        return PermissionStatusComparison(
            permissionType: permissionType,
            apiStatus: apiStatus,
            systemTCCStatus: systemTCCStatus,
            userTCCStatus: userTCCStatus,
            matchStatus: matchStatus
        )
    }
    
    private func authValueToString(_ authValue: Int?) -> String? {
        guard let value = authValue else { return nil }
        
        switch value {
        case 0:
            return "Denied"
        case 2:
            return "Granted"
        case 3:
            return "Limited"
        case 1:
            return "Unknown"
        default:
            return "Unknown (\(value))"
        }
    }
    
    // Convert various permission status enums to strings
    private func statusToString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusToString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusToString(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusToString(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .limited:
            return "Limited"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusToString(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .writeOnly:
            return "Write Only"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusToString(_ status: CNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusesMatch(apiStatus: String, tccStatus: String) -> Bool {
        let normalizedAPI = apiStatus.lowercased()
        let normalizedTCC = tccStatus.lowercased()
        
        // Check for direct match
        if normalizedAPI == normalizedTCC {
            return true
        }
        
        // Check for equivalent statuses
        let grantedStatuses = ["granted", "authorized", "limited"]
        let deniedStatuses = ["denied", "notdetermined", "restricted"]
        
        let apiGranted = grantedStatuses.contains { normalizedAPI.contains($0) }
        let tccGranted = grantedStatuses.contains { normalizedTCC.contains($0) }
        let apiDenied = deniedStatuses.contains { normalizedAPI.contains($0) }
        let tccDenied = deniedStatuses.contains { normalizedTCC.contains($0) }
        
        return (apiGranted && tccGranted) || (apiDenied && tccDenied)
    }
    
    private func errorComparison(for permissionType: PermissionType, error: Error) -> PermissionStatusComparison {
        return PermissionStatusComparison(
            permissionType: permissionType,
            apiStatus: "Error",
            systemTCCStatus: nil,
            userTCCStatus: nil,
            matchStatus: .error(error.localizedDescription)
        )
    }
}

enum PermissionType: String {
    case notifications = "Notifications"
    case location = "Location"
    case microphone = "Microphone"
    case camera = "Camera"
    case screenRecording = "Screen Recording"
    case screenSharing = "Screen Sharing"
    case fullDiskAccess = "Full Disk Access"
    case accessibility = "Accessibility"
    case filesAndFolders = "Files and Folders"
    case photos = "Photos"
    case calendar = "Calendar"
    case contacts = "Contacts"
    case bluetooth = "Bluetooth"
    case reminders = "Reminders"
    case appleEvents = "Apple Events"
}

