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

