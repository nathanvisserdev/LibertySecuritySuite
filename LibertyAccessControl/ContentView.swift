//
//  ContentView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    AllowRemoteFileAccessView()
                } label: {
                    Label("Grant Remote File Access", systemImage: "shield.checkered")
                }
                
                NavigationLink {
                    ScreenSharingView()
                } label: {
                    Label("Screen Sharing", systemImage: "rectangle.on.rectangle")
                }
                
                NavigationLink {
                    RemoteManagementView()
                } label: {
                    Label("Remote Management", systemImage: "desktopcomputer")
                }
                
                NavigationLink {
                    SSHView()
                } label: {
                    Label("SSH Access", systemImage: "terminal.fill")
                }
                
                NavigationLink {
                    UserPermissionsView()
                } label: {
                    Label("User Permissions", systemImage: "person.circle")
                }
                
                NavigationLink {
                    SystemPermissionsView()
                } label: {
                    Label("System Permissions", systemImage: "server.rack")
                }
                
                NavigationLink {
                    PermissionsView()
                } label: {
                    Label("Permissions", systemImage: "checklist")
                }
                
                NavigationLink {
                    RequestPermissionsView()
                } label: {
                    Label("Request Permissions", systemImage: "hand.raised.fill")
                }
                
                NavigationLink {
                    AppPermissionsView()
                } label: {
                    Label("App Permissions", systemImage: "checkmark.shield.fill")
                }
                
                NavigationLink {
                    REGView()
                } label: {
                    Label("TCC Registry", systemImage: "doc.text.fill")
                }
                
                NavigationLink {
                    NotificationsView()
                } label: {
                    Label("Notifications", systemImage: "bell.badge.fill")
                }
                
                NavigationLink {
                    LocationView()
                } label: {
                    Label("Location", systemImage: "location.fill")
                }
                
                NavigationLink {
                    MicrophoneView()
                } label: {
                    Label("Microphone", systemImage: "mic.fill")
                }
                
                NavigationLink {
                    CameraView()
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                }
                
                NavigationLink {
                    ScreenRecordingView()
                } label: {
                    Label("Screen Recording", systemImage: "record.circle.fill")
                }
                
                NavigationLink {
                    FullDiskAccessView()
                } label: {
                    Label("Full Disk Access", systemImage: "internaldrive.fill")
                }
                
                NavigationLink {
                    AccessibilityView()
                } label: {
                    Label("Accessibility", systemImage: "accessibility.fill")
                }
                
                NavigationLink {
                    FilesAndFoldersView()
                } label: {
                    Label("Files and Folders", systemImage: "folder.fill")
                }
                
                NavigationLink {
                    PhotosView()
                } label: {
                    Label("Photos", systemImage: "photo.fill")
                }
                
                NavigationLink {
                    CalendarView()
                } label: {
                    Label("Calendar", systemImage: "calendar")
                }
                
                NavigationLink {
                    ContactsView()
                } label: {
                    Label("Contacts", systemImage: "person.crop.circle.fill")
                }
                
                NavigationLink {
                    BluetoothView()
                } label: {
                    Label("Bluetooth", systemImage: "dot.radiowaves.left.and.right")
                }
                
                NavigationLink {
                    RemindersView()
                } label: {
                    Label("Reminders", systemImage: "checklist")
                }
                
                NavigationLink {
                    SpeechRecognitionView()
                } label: {
                    Label("Speech Recognition", systemImage: "waveform")
                }
                
                NavigationLink {
                    AppleEventsView()
                } label: {
                    Label("Apple Events", systemImage: "applescript.fill")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    ContentView()
}
