//
//  ReqListView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct ReqListView: View {
    @StateObject private var viewModel = ReqListViewModel()
    @State private var showHistory = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
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
                    
                    // Messages
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    if let successMessage = viewModel.successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    // Permission Request Buttons Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                        PermissionRequestButton(
                            title: "Notifications",
                            icon: "bell.badge.fill",
                            color: .blue
                        ) {
                            viewModel.requestPermission(for: .notifications)
                        }
                        
                        PermissionRequestButton(
                            title: "Location",
                            icon: "location.fill",
                            color: .green
                        ) {
                            viewModel.requestPermission(for: .location)
                        }
                        
                        PermissionRequestButton(
                            title: "Microphone",
                            icon: "mic.fill",
                            color: .red
                        ) {
                            viewModel.requestPermission(for: .microphone)
                        }
                        
                        PermissionRequestButton(
                            title: "Camera",
                            icon: "camera.fill",
                            color: .purple
                        ) {
                            viewModel.requestPermission(for: .camera)
                        }
                        
                        PermissionRequestButton(
                            title: "Screen Recording",
                            icon: "record.circle.fill",
                            color: .orange
                        ) {
                            viewModel.requestPermission(for: .screenRecording)
                        }
                        
                        PermissionRequestButton(
                            title: "Screen Sharing",
                            icon: "rectangle.on.rectangle",
                            color: .cyan
                        ) {
                            viewModel.requestPermission(for: .screenSharing)
                        }
                        
                        PermissionRequestButton(
                            title: "Full Disk Access",
                            icon: "internaldrive.fill",
                            color: .indigo
                        ) {
                            viewModel.requestPermission(for: .fullDiskAccess)
                        }
                        
                        PermissionRequestButton(
                            title: "Accessibility",
                            icon: "accessibility",
                            color: .pink
                        ) {
                            viewModel.requestPermission(for: .accessibility)
                        }
                        
                        PermissionRequestButton(
                            title: "Files & Folders",
                            icon: "folder.fill",
                            color: .yellow
                        ) {
                            viewModel.requestPermission(for: .filesAndFolders)
                        }
                        
                        PermissionRequestButton(
                            title: "Photos",
                            icon: "photo.fill",
                            color: .blue
                        ) {
                            viewModel.requestPermission(for: .photos)
                        }
                        
                        PermissionRequestButton(
                            title: "Calendar",
                            icon: "calendar",
                            color: .red
                        ) {
                            viewModel.requestPermission(for: .calendar)
                        }
                        
                        PermissionRequestButton(
                            title: "Contacts",
                            icon: "person.crop.circle.fill",
                            color: .green
                        ) {
                            viewModel.requestPermission(for: .contacts)
                        }
                        
                        PermissionRequestButton(
                            title: "Bluetooth",
                            icon: "wave.3.right.circle.fill",
                            color: .blue
                        ) {
                            viewModel.requestPermission(for: .bluetooth)
                        }
                        
                        PermissionRequestButton(
                            title: "Reminders",
                            icon: "checklist",
                            color: .orange
                        ) {
                            viewModel.requestPermission(for: .reminders)
                        }
                        
                        PermissionRequestButton(
                            title: "Apple Events",
                            icon: "applescript.fill",
                            color: .gray
                        ) {
                            viewModel.requestPermission(for: .appleEvents)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // History Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Request History")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showHistory.toggle() }) {
                                HStack {
                                    Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                                    Text(showHistory ? "Hide" : "Show")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            
                            if !viewModel.model.requestHistory.isEmpty {
                                Button(action: { viewModel.clearHistory() }) {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if showHistory {
                            if viewModel.model.requestHistory.isEmpty {
                                Text("No permission requests yet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(viewModel.getAllHistory()) { request in
                                    HistoryEntryView(request: request)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Request Permissions")
    }
}

// Permission Request Button Component
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

// History Entry View Component
struct HistoryEntryView: View {
    let request: PermissionRequest
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: request.granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(request.granted ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.type.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(request.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(request.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(6)
    }
}

#Preview {
    ReqListView()
}

