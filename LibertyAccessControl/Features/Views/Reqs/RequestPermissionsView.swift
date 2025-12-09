//
//  RequestPermissionsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct RequestPermissionsView: View {
    @StateObject private var viewModel = RequestPermissionsVM()
    @State private var showingDiscrepanciesOnly = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Permission Requests")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Check and request permissions. Compares API status with TCC database.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(viewModel.statusMessage, systemImage: viewModel.isLoading ? "arrow.clockwise" : "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(viewModel.statusMessage.contains("⚠️") ? .orange : .secondary)
                    
                    Spacer()
                    
                    Toggle("Discrepancies Only", isOn: $showingDiscrepanciesOnly)
                        .toggleStyle(.switch)
                        .font(.caption)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.loadAllPermissions()
                }) {
                    Label("Check All Permissions", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                
                if !viewModel.getDiscrepancies().isEmpty {
                    Text("\(viewModel.getDiscrepancies().count) discrepancies")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Permission List
            if viewModel.isLoading && viewModel.permissionStatuses.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Checking permissions...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.permissionStatuses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No permissions checked yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Click 'Check All Permissions' to begin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredPermissions) { comparison in
                            PermissionRow(
                                comparison: comparison,
                                onRequest: {
                                    viewModel.requestPermission(comparison.permissionType)
                                },
                                onRefresh: {
                                    viewModel.checkPermission(comparison.permissionType)
                                }
                            )
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.permissionStatuses.isEmpty {
                viewModel.loadAllPermissions()
            }
        }
    }
    
    private var filteredPermissions: [PermissionStatusComparison] {
        if showingDiscrepanciesOnly {
            return viewModel.permissionStatuses.filter { $0.hasDiscrepancy }
        }
        return viewModel.permissionStatuses
    }
}

struct PermissionRow: View {
    let comparison: PermissionStatusComparison
    let onRequest: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: iconForPermission(comparison.permissionType))
                    .font(.system(size: 24))
                    .foregroundColor(comparison.hasDiscrepancy ? .orange : .blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Permission Name
                    HStack {
                        Text(comparison.permissionType.rawValue)
                            .font(.headline)
                        
                        if comparison.hasDiscrepancy {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    
                    // API Status
                    HStack(spacing: 8) {
                        Text("API Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        StatusBadge(status: comparison.apiStatus, type: .api)
                    }
                    
                    // TCC Database Status
                    if let userTCC = comparison.userTCCStatus {
                        HStack(spacing: 8) {
                            Text("User TCC:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            StatusBadge(status: userTCC, type: .tcc)
                        }
                    }
                    
                    if let systemTCC = comparison.systemTCCStatus {
                        HStack(spacing: 8) {
                            Text("System TCC:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            StatusBadge(status: systemTCC, type: .tcc)
                        }
                    }
                    
                    // Discrepancy Warning
                    if let discrepancy = comparison.discrepancyDescription {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text(discrepancy)
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 8) {
                    Button(action: onRequest) {
                        Text("Request")
                            .font(.caption)
                            .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
    
    private func iconForPermission(_ permission: PermissionType) -> String {
        switch permission {
        case .notifications:
            return "bell.fill"
        case .location:
            return "location.fill"
        case .microphone:
            return "mic.fill"
        case .camera:
            return "camera.fill"
        case .screenRecording:
            return "record.circle"
        case .screenSharing:
            return "rectangle.on.rectangle"
        case .fullDiskAccess:
            return "externaldrive.fill"
        case .accessibility:
            return "accessibility"
        case .filesAndFolders:
            return "folder.fill"
        case .photos:
            return "photo.fill"
        case .calendar:
            return "calendar"
        case .contacts:
            return "person.crop.circle.fill"
        case .bluetooth:
            return "antenna.radiowaves.left.and.right"
        case .reminders:
            return "checklist"
        case .appleEvents:
            return "applescript"
        }
    }
}

struct StatusBadge: View {
    let status: String
    let type: StatusType
    
    enum StatusType {
        case api
        case tcc
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        let normalizedStatus = status.lowercased()
        
        if normalizedStatus.contains("granted") || normalizedStatus.contains("authorized") {
            return .green.opacity(0.2)
        } else if normalizedStatus.contains("limited") {
            return .yellow.opacity(0.2)
        } else if normalizedStatus.contains("denied") || normalizedStatus.contains("restricted") {
            return .red.opacity(0.2)
        } else {
            return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        let normalizedStatus = status.lowercased()
        
        if normalizedStatus.contains("granted") || normalizedStatus.contains("authorized") {
            return .green
        } else if normalizedStatus.contains("limited") {
            return .orange
        } else if normalizedStatus.contains("denied") || normalizedStatus.contains("restricted") {
            return .red
        } else {
            return .gray
        }
    }
}

#Preview {
    RequestPermissionsView()
        .frame(width: 800, height: 600)
}
