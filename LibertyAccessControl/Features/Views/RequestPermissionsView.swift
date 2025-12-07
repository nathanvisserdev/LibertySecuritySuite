//
//  RequestPermissionsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import SwiftUI

struct RequestPermissionsView: View {
    @StateObject private var viewModel = RequestPermissionsViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Request Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            ScrollView {
                VStack(spacing: 15) {
                    PermissionButton(title: "Accessibility", icon: "accessibility", action: {})
                    PermissionButton(title: "Allow Remote File Access", icon: "arrow.down.doc", action: {})
                    PermissionButton(title: "Apple Events", icon: "applescript", action: {})
                    PermissionButton(title: "Bluetooth", icon: "dot.radiowaves.left.and.right", action: {})
                    PermissionButton(title: "Calendar", icon: "calendar", action: {})
                    PermissionButton(title: "Camera", icon: "camera.fill", action: {})
                    PermissionButton(title: "Contacts", icon: "person.crop.circle.fill", action: {})
                    PermissionButton(title: "Files and Folders", icon: "folder.fill", action: {})
                    PermissionButton(title: "Full Disk Access", icon: "internaldrive.fill", action: {})
                    PermissionButton(title: "Location", icon: "location.fill", action: {})
                    PermissionButton(title: "Microphone", icon: "mic.fill", action: {})
                    PermissionButton(title: "Notifications", icon: "bell.badge.fill", action: {})
                    PermissionButton(title: "Photos", icon: "photo.fill", action: {})
                    PermissionButton(title: "Reminders", icon: "checklist", action: {})
                    PermissionButton(title: "Remote Management", icon: "network", action: {})
                    PermissionButton(title: "Screen Recording", icon: "record.circle", action: {})
                    PermissionButton(title: "Screen Sharing", icon: "rectangle.on.rectangle", action: {})
                    PermissionButton(title: "Speech Recognition", icon: "waveform", action: {})
                    PermissionButton(title: "SSH", icon: "terminal", action: {})
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct PermissionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 30)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.accentColor)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlColor))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RequestPermissionsView()
}
