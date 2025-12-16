//
//  DashboardView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import SwiftUI

struct DashboardView: View {
    @State private var selectedView: DashboardTab = .permissions
    @EnvironmentObject private var monitoringService: ReqMonVM
    
    enum DashboardTab {
        case permissions
        case user
        case system
        case registry
        case fileEncryptGPG
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Area with embedded toolbar
            Group {
                switch selectedView {
                case .permissions:
                    PermissionsView()
                case .user:
                    UserView()
                case .system:
                    SystemView()
                case .registry:
                    REGView()
                case .fileEncryptGPG:
                    FileEncryptGPGView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Button("All") {
                        selectedView = .permissions
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .permissions ? .blue : .primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("User") {
                        selectedView = .user
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .user ? .blue : .primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("System") {
                        selectedView = .system
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .system ? .blue : .primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("Registry") {
                        selectedView = .registry
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .registry ? .blue : .primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("File Encrypt (GPG)") {
                        selectedView = .fileEncryptGPG
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .fileEncryptGPG ? .blue : .primary)
                }
            }
            
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 12) {
                    // Request count
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(monitoringService.accessRequests.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(monitoringService.isNotificationsEnabled ? .green : .secondary)
                        
                        Text("requests")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Monitoring toggle
                    VStack(alignment: .trailing, spacing: 2) {
                        Toggle("", isOn: Binding(
                            get: { monitoringService.isNotificationsEnabled },
                            set: { isOn in
                                if isOn {
                                    monitoringService.startBackgroundMonitoring()
                                } else {
                                    monitoringService.stopBackgroundMonitoring()
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                        
                        Text(monitoringService.isNotificationsEnabled ? "Active" : "Inactive")
                            .font(.caption2)
                            .foregroundColor(monitoringService.isNotificationsEnabled ? .green : .secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(ReqMonVM(
            monitorService: SystemMonitorService(
                parser: TCCLogParser(),
                notificationService: NotificationService(
                    preferences: MonitoringPreferences(),
                    trustManager: AppTrustManager(preferences: MonitoringPreferences())
                )
            ),
            notificationService: NotificationService(
                preferences: MonitoringPreferences(),
                trustManager: AppTrustManager(preferences: MonitoringPreferences())
            )
        ))
}
