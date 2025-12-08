//
//  RequestListView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct RequestListView: View {
    @State private var notifications: [String] = []
    @State private var location: [String] = []
    @State private var microphone: [String] = []
    @State private var camera: [String] = []
    @State private var screenRecording: [String] = []
    @State private var fullDiskAccess: [String] = []
    @State private var accessibility: [String] = []
    @State private var filesAndFolders: [String] = []
    @State private var photos: [String] = []
    @State private var calendar: [String] = []
    @State private var contacts: [String] = []
    @State private var bluetooth: [String] = []
    @State private var reminders: [String] = []
    @State private var speechRecognition: [String] = []
    @State private var appleEvents: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Request List")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("View and manage permission requests")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Divider()
                
                // Permission Lists
                VStack(alignment: .leading, spacing: 16) {
                    PermissionSection(title: "Notifications", icon: "bell.badge.fill", items: notifications)
                    PermissionSection(title: "Location", icon: "location.fill", items: location)
                    PermissionSection(title: "Microphone", icon: "mic.fill", items: microphone)
                    PermissionSection(title: "Camera", icon: "camera.fill", items: camera)
                    PermissionSection(title: "Screen Recording", icon: "record.circle.fill", items: screenRecording)
                    PermissionSection(title: "Full Disk Access", icon: "internaldrive.fill", items: fullDiskAccess)
                    PermissionSection(title: "Accessibility", icon: "accessibility", items: accessibility)
                    PermissionSection(title: "Files and Folders", icon: "folder.fill", items: filesAndFolders)
                    PermissionSection(title: "Photos", icon: "photo.fill", items: photos)
                    PermissionSection(title: "Calendar", icon: "calendar", items: calendar)
                    PermissionSection(title: "Contacts", icon: "person.crop.circle.fill", items: contacts)
                    PermissionSection(title: "Bluetooth", icon: "wave.3.right.circle.fill", items: bluetooth)
                    PermissionSection(title: "Reminders", icon: "checklist", items: reminders)
                    PermissionSection(title: "Speech Recognition", icon: "waveform", items: speechRecognition)
                    PermissionSection(title: "Apple Events", icon: "applescript.fill", items: appleEvents)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Request List")
    }
}

struct PermissionSection: View {
    let title: String
    let icon: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if items.isEmpty {
                Text("No entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            } else {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.body)
                        .padding(.leading, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    RequestListView()
}
