//
//  AppPermissionsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import SwiftUI

struct AppPermissionsView: View {
    @StateObject private var viewModel: AppPermissionsViewModel
    
    init() {
        let systemService = SystemService()
        _viewModel = StateObject(wrappedValue: AppPermissionsViewModel(SystemService: systemService))
    }
    
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
                    PermissionStatusRow(title: "Accessibility", icon: "accessibility", status: viewModel.permissionStatuses["Accessibility"] ?? "Not Checked", isConfigured: true, configNote: nil, action: nil)
                    PermissionStatusRow(title: "Allow Remote File Access", icon: "arrow.down.doc", status: viewModel.permissionStatuses["Allow Remote File Access"] ?? "Not Checked", isConfigured: false, configNote: "Check via system preferences or MDM queries", action: { viewModel.checkRemoteFileAccess() })
                    PermissionStatusRow(title: "Apple Events", icon: "applescript", status: viewModel.permissionStatuses["Apple Events"] ?? "Not Checked", isConfigured: false, configNote: "Query TCC database or attempt to send Apple Events to target app", action: { viewModel.checkAppleEvents() })
                    AppManagementPermissionRow(viewModel: viewModel)
                    PermissionStatusRow(title: "Bluetooth", icon: "dot.radiowaves.left.and.right", status: viewModel.permissionStatuses["Bluetooth"] ?? "Not Checked", isConfigured: false, configNote: "Initialize CBCentralManager and check its authorization status", action: { viewModel.checkBluetooth() })
                    CalendarPermissionRow(viewModel: viewModel)
                    CameraPermissionRow(viewModel: viewModel)
                    ContactsPermissionRow(viewModel: viewModel)
                    PermissionStatusRow(title: "Files and Folders", icon: "folder.fill", status: viewModel.permissionStatuses["Files and Folders"] ?? "Not Checked", isConfigured: false, configNote: "Attempt to access specific protected directories (Documents, Downloads, etc.)", action: { viewModel.checkFilesAndFolders() })
                    PermissionStatusRow(title: "Full Disk Access", icon: "internaldrive.fill", status: viewModel.permissionStatuses["Full Disk Access"] ?? "Not Checked", isConfigured: false, configNote: "Attempt to read system-protected files like ~/Library/Safari/History.db", action: { viewModel.checkFullDiskAccess() })
                    PermissionStatusRow(title: "Location", icon: "location.fill", status: viewModel.permissionStatuses["Location"] ?? "Not Checked", isConfigured: true, configNote: nil, action: nil)
                    MicrophonePermissionRow(viewModel: viewModel)
                    PermissionStatusRow(title: "Notifications", icon: "bell.badge.fill", status: viewModel.permissionStatuses["Notifications"] ?? "Not Checked", isConfigured: true, configNote: nil, action: nil)
                    PhotosPermissionRow(viewModel: viewModel)
                    RemindersPermissionRow(viewModel: viewModel)
                    PermissionStatusRow(title: "Remote Management", icon: "network", status: viewModel.permissionStatuses["Remote Management"] ?? "Not Checked", isConfigured: false, configNote: "Check MDM enrollment status via IOKit or profiles", action: { viewModel.checkRemoteManagement() })
                    ScreenRecordingPermissionRow(viewModel: viewModel)
                    SpeechRecognitionPermissionRow(viewModel: viewModel)
                    PermissionStatusRow(title: "SSH", icon: "terminal", status: viewModel.permissionStatuses["SSH"] ?? "Not Checked", isConfigured: false, configNote: "Check if SSH daemon is enabled via system configuration", action: { viewModel.checkSSH() })
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            viewModel.checkAllPermissions()
            viewModel.checkNotifications { status in
                viewModel.permissionStatuses["Notifications"] = status
            }
        }
    }
}

struct CameraPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Camera"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case _ where status.contains("Authorized"):
            return .green
        case _ where status.contains("Denied"), _ where status.contains("Restricted"):
            return .red
        case _ where status.contains("Not yet requested"), _ where status.contains("Not Checked"), _ where status.contains("Not Determined"):
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Camera")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status == "AV Authorization Status: Not yet requested" {
                    Button("Request") {
                        viewModel.requestCameraPermission { newStatus in
                            viewModel.permissionStatuses["Camera"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct CalendarPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Calendar"] ?? "Indeterminable upon request"
    }
    
    var statusColor: Color {
        switch status {
        case "Authorized", "Full Access":
            return .green
        case "Denied", "Restricted":
            return .red
        case "Not Determined", "Not Checked", "Indeterminable upon request":
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Calendar")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Request") {
                    viewModel.checkCalendar { newStatus in
                        viewModel.permissionStatuses["Calendar"] = newStatus
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("⚠️ On macOS 14+: Checking status requires requesting permission.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 38)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct RemindersPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Reminders"] ?? "Indeterminable upon request"
    }
    
    var statusColor: Color {
        switch status {
        case "Authorized", "Full Access":
            return .green
        case "Denied", "Restricted":
            return .red
        case "Not Determined", "Not Checked", "Indeterminable upon request":
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Reminders")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Request") {
                    viewModel.checkReminders { newStatus in
                        viewModel.permissionStatuses["Reminders"] = newStatus
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("⚠️ On macOS 14+: Checking status requires requesting permission")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 38)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct ScreenRecordingPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Screen Recording"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case "Authorized", "Full Access":
            return .green
        case "Denied", "Restricted":
            return .red
        case "Not Determined", "Not Checked":
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "record.circle")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Screen Recording")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status.contains("Not Authorized") {
                    Button("Request") {
                        viewModel.requestScreenRecordingPermission { newStatus in
                            viewModel.permissionStatuses["Screen Recording"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Text("⚠️ Returns true or false. Does not indicate if previous request was made.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 38)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct PermissionStatusRow: View {
    let title: String
    let icon: String
    let status: String
    let isConfigured: Bool
    let configNote: String?
    let action: (() -> Void)?
    
    var statusColor: Color {
        switch status {
        case "Authorized", "Authorized Always", "Authorized When In Use":
            return .green
        case "Denied", "Restricted":
            return .red
        case "Not Determined", "Not Checked", "Not yet requested":
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
                
                if !isConfigured {
                    Text("❌")
                        .font(.body)
                }
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if let action = action {
                    Button(action: action) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
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

struct ContactsPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Contacts"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case _ where status.contains("Authorized"):
            return .green
        case _ where status.contains("Denied"), _ where status.contains("Restricted"):
            return .red
        case _ where status.contains("Not Determined"), _ where status.contains("Not Checked"):
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Contacts")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status.contains("Not Determined") {
                    Button("Request") {
                        viewModel.requestContactsPermission { newStatus in
                            viewModel.permissionStatuses["Contacts"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct MicrophonePermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Microphone"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case _ where status.contains("Authorized"):
            return .green
        case _ where status.contains("Denied"), _ where status.contains("Restricted"):
            return .red
        case _ where status.contains("Not yet requested"), _ where status.contains("Not Checked"):
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Microphone")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status.contains("Not yet requested") {
                    Button("Request") {
                        viewModel.requestMicrophonePermission { newStatus in
                            viewModel.permissionStatuses["Microphone"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct PhotosPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Photos"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case _ where status.contains("Authorized"):
            return .green
        case _ where status.contains("Denied"), _ where status.contains("Restricted"):
            return .red
        case _ where status.contains("Not Determined"), _ where status.contains("Not Checked"):
            return .orange
        case _ where status.contains("Limited"):
            return .yellow
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo.fill")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Photos")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status.contains("Not Determined") {
                    Button("Request") {
                        viewModel.requestPhotosPermission { newStatus in
                            viewModel.permissionStatuses["Photos"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct SpeechRecognitionPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["Speech Recognition"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case _ where status.contains("Authorized"):
            return .green
        case _ where status.contains("Denied"), _ where status.contains("Restricted"):
            return .red
        case _ where status.contains("Not Determined"), _ where status.contains("Not Checked"):
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("Speech Recognition")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status.contains("Not Determined") {
                    Button("Request") {
                        viewModel.requestSpeechRecognitionPermission { newStatus in
                            viewModel.permissionStatuses["Speech Recognition"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlColor))
        .cornerRadius(10)
    }
}

struct AppManagementPermissionRow: View {
    @ObservedObject var viewModel: AppPermissionsViewModel
    
    var status: String {
        viewModel.permissionStatuses["App Management"] ?? "Not Checked"
    }
    
    var statusColor: Color {
        switch status {
        case _ where status.contains("Authorized"):
            return .green
        case _ where status.contains("Denied"):
            return .red
        case _ where status.contains("Entry Not Found"), _ where status.contains("Not Checked"):
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "app.badge")
                    .font(.title2)
                    .frame(width: 30)
                
                Text("App Management")
                    .font(.body)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                
                if status.contains("Entry Not Found") {
                    Button("Request") {
                        viewModel.requestAppManagementPermission { newStatus in
                            viewModel.permissionStatuses["App Management"] = newStatus
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
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
