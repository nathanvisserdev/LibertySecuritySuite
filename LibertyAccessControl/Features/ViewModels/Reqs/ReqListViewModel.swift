//
//  ReqListViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Combine
import UserNotifications
import CoreLocation
import AVFoundation
import Photos
import EventKit
import Contacts

@MainActor
class ReqListViewModel: ObservableObject {
    @Published var model = ReqListModel()
    @Published var notificationStatus: UNAuthStatDTO?
    @Published var locationStatus: CLAuthStatDTO?
    @Published var microphoneStatus: AVAuthStatDTO?
    @Published var cameraStatus: AVAuthStatDTO?
    @Published var photosStatus: PHAuthStatDTO?
    @Published var calendarStatus: EKAuthStatDTO?
    @Published var contactsStatus: CNAuthStatDTO?
    @Published var remindersStatus: EKAuthStatDTO?
    
    func requestNotificationPermission() {
        Task {
            notificationStatus = try? await model.requestNotificationPermission()
        }
    }
    
    func requestLocationPermission() {
        Task {
            locationStatus = try? await model.requestLocationPermission()
        }
    }
    
    func requestMicrophonePermission() {
        Task {
            microphoneStatus = try? await model.requestMicrophonePermission()
        }
    }
    
    func requestCameraPermission() {
        Task {
            cameraStatus = try? await model.requestCameraPermission()
        }
    }
    
    func requestPhotosPermission() {
        Task {
            photosStatus = try? await model.requestPhotosPermission()
        }
    }
    
    func requestCalendarPermission() {
        Task {
            calendarStatus = try? await model.requestCalendarPermission()
        }
    }
    
    func requestContactsPermission() {
        Task {
            contactsStatus = try? await model.requestContactsPermission()
        }
    }
    
    func requestRemindersPermission() {
        Task {
            remindersStatus = try? await model.requestRemindersPermission()
        }
    }
    
    func clearAllStatuses() {
        notificationStatus = nil
        locationStatus = nil
        microphoneStatus = nil
        cameraStatus = nil
        photosStatus = nil
        calendarStatus = nil
        contactsStatus = nil
        remindersStatus = nil
    }
}
