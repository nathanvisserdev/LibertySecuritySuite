//
//  ReqListModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

struct ReqListModel {
    // Service dependencies
    let notificationService: NotReqServ
    let locationService: LocReqServ
    let microphoneService: MicReqServ
    let cameraService: CamReqServ
    let screenRecordingService: SRRecServ
    let screenSharingService: SSRecServ
    let fullDiskAccessService: FDAReqServ
    let accessibilityService: AccReqServ
    let filesAndFoldersService: FFReqServ
    let photosService: PhoReqServ
    let calendarService: CalReqServ
    let contactsService: ContReqServ
    let bluetoothService: BTReqServ
    let remindersService: RemReqServ
    let appleEventsService: AEReqServ
    
    init(
        notificationService: NotReqServ = NotReqServ(),
        locationService: LocReqServ = LocReqServ(),
        microphoneService: MicReqServ = MicReqServ(),
        cameraService: CamReqServ = CamReqServ(),
        screenRecordingService: SRRecServ = SRRecServ(),
        screenSharingService: SSRecServ = SSRecServ(),
        fullDiskAccessService: FDAReqServ = FDAReqServ(),
        accessibilityService: AccReqServ = AccReqServ(),
        filesAndFoldersService: FFReqServ = FFReqServ(),
        photosService: PhoReqServ = PhoReqServ(),
        calendarService: CalReqServ = CalReqServ(),
        contactsService: ContReqServ = ContReqServ(),
        bluetoothService: BTReqServ = BTReqServ(),
        remindersService: RemReqServ = RemReqServ(),
        appleEventsService: AEReqServ = AEReqServ()
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
    }
    
    // Request methods that delegate to services
    // NOTE: 'mutating' keyword causes 'self' to be passed as 'inout', which conflicts with actor isolation in @MainActor contexts
    func requestNotificationPermission() async throws -> PermissionRequest {
        let result = try await notificationService.requestPermission()
        let request = PermissionRequest(
            type: .notifications,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestLocationPermission() async throws -> PermissionRequest {
        let result = try await locationService.requestPermission()
        let request = PermissionRequest(
            type: .location,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestMicrophonePermission() async throws -> PermissionRequest {
        let result = try await microphoneService.requestPermission()
        let request = PermissionRequest(
            type: .microphone,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestCameraPermission() async throws -> PermissionRequest {
        let result = try await cameraService.requestPermission()
        let request = PermissionRequest(
            type: .camera,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestScreenRecordingPermission() async throws -> PermissionRequest {
        let result = try await screenRecordingService.requestPermission()
        let request = PermissionRequest(
            type: .screenRecording,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestScreenSharingPermission() async throws -> PermissionRequest {
        let result = try await screenSharingService.requestPermission()
        let request = PermissionRequest(
            type: .screenSharing,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestFullDiskAccessPermission() async throws -> PermissionRequest {
        let result = try await fullDiskAccessService.requestPermission()
        let request = PermissionRequest(
            type: .fullDiskAccess,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestAccessibilityPermission() async throws -> PermissionRequest {
        let result = try await accessibilityService.requestPermission()
        let request = PermissionRequest(
            type: .accessibility,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestFilesAndFoldersPermission() async throws -> PermissionRequest {
        let result = try await filesAndFoldersService.requestPermission()
        let request = PermissionRequest(
            type: .filesAndFolders,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestPhotosPermission() async throws -> PermissionRequest {
        let result = try await photosService.requestPermission()
        let request = PermissionRequest(
            type: .photos,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestCalendarPermission() async throws -> PermissionRequest {
        let result = try await calendarService.requestPermission()
        let request = PermissionRequest(
            type: .calendar,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestContactsPermission() async throws -> PermissionRequest {
        let result = try await contactsService.requestPermission()
        let request = PermissionRequest(
            type: .contacts,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestBluetoothPermission() async -> PermissionRequest {
        let result = await bluetoothService.requestPermission()
        let request = PermissionRequest(
            type: .bluetooth,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestRemindersPermission() async throws -> PermissionRequest {
        let result = try await remindersService.requestPermission()
        let request = PermissionRequest(
            type: .reminders,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
    
    func requestAppleEventsPermission() async throws -> PermissionRequest {
        let result = try await appleEventsService.requestPermission()
        let request = PermissionRequest(
            type: .appleEvents,
            granted: result.granted,
            message: result.message,
            timestamp: Date()
        )
        requestHistory.append(request)
        return request
    }
}

// Supporting types
struct PermissionRequest: Identifiable {
    let id = UUID()
    let type: PermissionType
    let granted: Bool
    let message: String
    let timestamp: Date
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

