//
//  ReqListModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

struct ReqListModel {
    let notificationService: NotReqServ
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
    
    init(
        notificationService: NotReqServ = NotReqServ(),
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
        let response = try await notificationService.reqPerm()
        return response
    }
    
    func requestLocationPermission() async throws -> PermissionRequest {
        return try await locationService.reqPerm()
    }
    
    func requestMicrophonePermission() async throws -> PermissionRequest {
        return try await microphoneService.reqPerm()
    }
    
    func requestCameraPermission() async throws -> PermissionRequest {
        return try await cameraService.reqPerm()
    }
    
    func requestScreenRecordingPermission() async throws -> PermissionRequest {
        return try await screenRecordingService.reqPerm()
    }
    
    func requestScreenSharingPermission() async throws -> PermissionRequest {
        return try await screenSharingService.reqPerm()
    }
    
    func requestFullDiskAccessPermission() async throws -> PermissionRequest {
        return try await fullDiskAccessService.reqPerm()
    }
    
    func requestAccessibilityPermission() async throws -> PermissionRequest {
        return try await accessibilityService.reqPerm()
    }
    
    func requestFilesAndFoldersPermission() async throws -> PermissionRequest {
        return try await filesAndFoldersService.reqPerm()
    }
    
    func requestPhotosPermission() async throws -> PHAuthorizationStatus {
        return try await photosService.reqPerm()
    }
    
    func requestCalendarPermission() async throws -> PermissionRequest {
        return try await calendarService.reqPerm()
    }
    
    func requestContactsPermission() async throws -> PermissionRequest {
        return try await contactsService.reqPerm()
    }
    
    func requestBluetoothPermission() async -> PermissionRequest {
        return await bluetoothService.reqPerm()
    }
    
    func requestRemindersPermission() async throws -> PermissionRequest {
        return try await remindersService.reqPerm()
    }
    
    func requestAppleEventsPermission() async throws -> PermissionRequest {
        return try await appleEventsService.reqPerm()
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

