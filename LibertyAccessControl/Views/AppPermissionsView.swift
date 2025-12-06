//
//  AppPermissionsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import SwiftUI

struct AppPermissionsView: View {
    @State private var viewModel = AppPermissionsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    viewModel.checkAllPermissions()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .padding()
                
                Spacer()
            }
            
            Text("App Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 15) {
                    PermissionStatusRow(title: "Accessibility", icon: "accessibility", status: viewModel.permissionStatuses["Accessibility"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkAccessibility() })
                    PermissionStatusRow(title: "Allow Remote File Access", icon: "arrow.down.doc", status: viewModel.permissionStatuses["Allow Remote File Access"] ?? "Not Checked", isConfigured: false, configNote: "Check via system preferences or MDM queries", action: { viewModel.checkRemoteFileAccess() })
                    PermissionStatusRow(title: "Apple Events", icon: "applescript", status: viewModel.permissionStatuses["Apple Events"] ?? "Not Checked", isConfigured: false, configNote: "Query TCC database or attempt to send Apple Events to target app", action: { viewModel.checkAppleEvents() })
                    PermissionStatusRow(title: "Bluetooth", icon: "dot.radiowaves.left.and.right", status: viewModel.permissionStatuses["Bluetooth"] ?? "Not Checked", isConfigured: false, configNote: "Initialize CBCentralManager and check its authorization status", action: { viewModel.checkBluetooth() })
                    PermissionStatusRow(title: "Calendar", icon: "calendar", status: viewModel.permissionStatuses["Calendar"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { 
                        viewModel.checkCalendar { status in
                            viewModel.permissionStatuses["Calendar"] = status
                        }
                    })
                    PermissionStatusRow(title: "Camera", icon: "camera.fill", status: viewModel.permissionStatuses["Camera"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkCamera() })
                    PermissionStatusRow(title: "Contacts", icon: "person.crop.circle.fill", status: viewModel.permissionStatuses["Contacts"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkContacts() })
                    PermissionStatusRow(title: "Files and Folders", icon: "folder.fill", status: viewModel.permissionStatuses["Files and Folders"] ?? "Not Checked", isConfigured: false, configNote: "Attempt to access specific protected directories (Documents, Downloads, etc.)", action: { viewModel.checkFilesAndFolders() })
                    PermissionStatusRow(title: "Full Disk Access", icon: "internaldrive.fill", status: viewModel.permissionStatuses["Full Disk Access"] ?? "Not Checked", isConfigured: false, configNote: "Attempt to read system-protected files like ~/Library/Safari/History.db", action: { viewModel.checkFullDiskAccess() })
                    PermissionStatusRow(title: "Location", icon: "location.fill", status: viewModel.permissionStatuses["Location"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkLocation() })
                    PermissionStatusRow(title: "Microphone", icon: "mic.fill", status: viewModel.permissionStatuses["Microphone"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkMicrophone() })
                    PermissionStatusRow(title: "Notifications", icon: "bell.badge.fill", status: viewModel.permissionStatuses["Notifications"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { 
                        viewModel.checkNotifications { status in
                            viewModel.permissionStatuses["Notifications"] = status
                        }
                    })
                    PermissionStatusRow(title: "Photos", icon: "photo.fill", status: viewModel.permissionStatuses["Photos"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkPhotos() })
                    PermissionStatusRow(title: "Reminders", icon: "checklist", status: viewModel.permissionStatuses["Reminders"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { 
                        viewModel.checkReminders { status in
                            viewModel.permissionStatuses["Reminders"] = status
                        }
                    })
                    PermissionStatusRow(title: "Remote Management", icon: "network", status: viewModel.permissionStatuses["Remote Management"] ?? "Not Checked", isConfigured: false, configNote: "Check MDM enrollment status via IOKit or profiles", action: { viewModel.checkRemoteManagement() })
                    PermissionStatusRow(title: "Screen Recording", icon: "record.circle", status: viewModel.permissionStatuses["Screen Recording"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkScreenRecording() })
                    PermissionStatusRow(title: "Speech Recognition", icon: "waveform", status: viewModel.permissionStatuses["Speech Recognition"] ?? "Not Checked", isConfigured: true, configNote: nil, action: { viewModel.checkSpeechRecognition() })
                    PermissionStatusRow(title: "SSH", icon: "terminal", status: viewModel.permissionStatuses["SSH"] ?? "Not Checked", isConfigured: false, configNote: "Check if SSH daemon is enabled via system configuration", action: { viewModel.checkSSH() })
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            viewModel.checkAllPermissions()
        }
    }
}

struct PermissionStatusRow: View {
    let title: String
    let icon: String
    let status: String
    let isConfigured: Bool
    let configNote: String?
    let action: () -> Void
    
    var statusColor: Color {
        switch status {
        case "Authorized", "Authorized Always", "Authorized When In Use":
            return .green
        case "Denied", "Restricted":
            return .red
        case "Not Determined", "Not Checked":
            return .orange
        case "Limited", "Provisional", "Ephemeral":
            return .yellow
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                
                Text(isConfigured ? "✅" : "❌")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                Button(action: action) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            
            if let note = configNote {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 38)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

#Preview {
    AppPermissionsView()
}
