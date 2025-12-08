//
//  RequestListView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct RequestListView: View {
    @StateObject private var viewModel = RequestListViewModel()
    
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
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Divider()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    // Permission Lists
                    VStack(alignment: .leading, spacing: 16) {
                        PermissionSection(title: "Notifications", icon: "bell.badge.fill", items: viewModel.model.notifications)
                        PermissionSection(title: "Location", icon: "location.fill", items: viewModel.model.location)
                        PermissionSection(title: "Microphone", icon: "mic.fill", items: viewModel.model.microphone)
                        PermissionSection(title: "Camera", icon: "camera.fill", items: viewModel.model.camera)
                        PermissionSection(title: "Screen Recording", icon: "record.circle.fill", items: viewModel.model.screenRecording)
                        PermissionSection(title: "Full Disk Access", icon: "internaldrive.fill", items: viewModel.model.fullDiskAccess)
                        PermissionSection(title: "Accessibility", icon: "accessibility", items: viewModel.model.accessibility)
                        PermissionSection(title: "Files and Folders", icon: "folder.fill", items: viewModel.model.filesAndFolders)
                        PermissionSection(title: "Photos", icon: "photo.fill", items: viewModel.model.photos)
                        PermissionSection(title: "Calendar", icon: "calendar", items: viewModel.model.calendar)
                        PermissionSection(title: "Contacts", icon: "person.crop.circle.fill", items: viewModel.model.contacts)
                        PermissionSection(title: "Bluetooth", icon: "wave.3.right.circle.fill", items: viewModel.model.bluetooth)
                        PermissionSection(title: "Reminders", icon: "checklist", items: viewModel.model.reminders)
                        PermissionSection(title: "Speech Recognition", icon: "waveform", items: viewModel.model.speechRecognition)
                        PermissionSection(title: "Apple Events", icon: "applescript.fill", items: viewModel.model.appleEvents)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Request List")
        .onAppear {
            viewModel.loadData()
        }
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
