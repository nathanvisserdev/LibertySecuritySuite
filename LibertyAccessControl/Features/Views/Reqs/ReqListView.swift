//
//  ReqListView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct ReqListView: View {
    @StateObject private var viewModel = ReqListViewModel()
    @State private var showStatusDisplay = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                Text("Request Permissions")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Request system permissions for your application")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Divider()
            
            // Permission Request Buttons Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                        PermissionRequestButton(
                            title: "Notifications",
                            icon: "bell.badge.fill",
                            color: .blue
                        ) {
                            viewModel.requestNotificationPermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Location",
                            icon: "location.fill",
                            color: .green
                        ) {
                            viewModel.requestLocationPermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Microphone",
                            icon: "mic.fill",
                            color: .red
                        ) {
                            viewModel.requestMicrophonePermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Camera",
                            icon: "camera.fill",
                            color: .purple
                        ) {
                            viewModel.requestCameraPermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Photos",
                            icon: "photo.fill",
                            color: .blue
                        ) {
                            viewModel.requestPhotosPermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Calendar",
                            icon: "calendar",
                            color: .red
                        ) {
                            viewModel.requestCalendarPermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Contacts",
                            icon: "person.crop.circle.fill",
                            color: .green
                        ) {
                            viewModel.requestContactsPermission()
                        }
                        
                        PermissionRequestButton(
                            title: "Reminders",
                            icon: "checklist",
                            color: .orange
                        ) {
                            viewModel.requestRemindersPermission()
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Status Display Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Authorization Status")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showStatusDisplay.toggle() }) {
                                HStack {
                                    Image(systemName: showStatusDisplay ? "chevron.up" : "chevron.down")
                                    Text(showStatusDisplay ? "Hide" : "Show")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            
                            Button(action: { viewModel.clearAllStatuses() }) {
                                Text("Clear")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if showStatusDisplay {
                            VStack(spacing: 8) {
                                if let status = viewModel.notificationStatus {
                                    StatusRow(title: "Notifications", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.locationStatus {
                                    StatusRow(title: "Location", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.microphoneStatus {
                                    StatusRow(title: "Microphone", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.cameraStatus {
                                    StatusRow(title: "Camera", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.photosStatus {
                                    StatusRow(title: "Photos", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.calendarStatus {
                                    StatusRow(title: "Calendar", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.contactsStatus {
                                    StatusRow(title: "Contacts", statusValue: statusToString(status.status))
                                }
                                
                                if let status = viewModel.remindersStatus {
                                    StatusRow(title: "Reminders", statusValue: statusToString(status.status))
                                }
                                
                                if viewModel.notificationStatus == nil && 
                                   viewModel.locationStatus == nil && 
                                   viewModel.microphoneStatus == nil && 
                                   viewModel.cameraStatus == nil && 
                                   viewModel.photosStatus == nil && 
                                   viewModel.calendarStatus == nil && 
                                   viewModel.contactsStatus == nil && 
                                   viewModel.remindersStatus == nil {
                                    Text("No permission responses yet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                        }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Request Permissions")
    }
    
    private func statusToString(_ status: Any) -> String {
        return String(describing: status)
    }
};struct StatusRow: View {
    let title: String
    let statusValue: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(statusValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(4)
        }
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(6)
    }
}

struct PermissionRequestButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReqListView()
}

