//
//  TCCUserView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct TCCUserView: View {
    @StateObject private var viewModel = TCCUserViewModel()
    @State private var expandedEntries: Set<UUID> = []
    @State private var expandedCategories: Set<String> = []
    
    // Service name to category mapping
    private let serviceCategories: [String: String] = [
        "kTCCServiceLocation": "Location Services",
        "kTCCServiceAddressBook": "Contacts",
        "kTCCServiceCalendar": "Calendars",
        "kTCCServiceReminders": "Reminders",
        "kTCCServicePhotos": "Photos",
        "kTCCServicePhotoAdd": "Photos",
        "kTCCServiceMediaLibrary": "Photos",
        "kTCCServiceCamera": "Camera",
        "kTCCServiceMicrophone": "Microphone",
        "kTCCServiceAccessibility": "Accessibility",
        "kTCCServicePostEvent": "Input Monitoring",
        "kTCCServiceListenEvent": "Input Monitoring",
        "kTCCServiceScreenCapture": "Screen & System Audio Recording",
        "kTCCServiceSystemPolicyAllFiles": "Full Disk Access",
        "kTCCServiceSystemPolicyDesktopFolder": "Files & Folders",
        "kTCCServiceSystemPolicyDocumentsFolder": "Files & Folders",
        "kTCCServiceSystemPolicyDownloadsFolder": "Files & Folders",
        "kTCCServiceSystemPolicyNetworkVolumes": "Files & Folders",
        "kTCCServiceSystemPolicyRemovableVolumes": "Files & Folders",
        "kTCCServiceSystemPolicySysAdminFiles": "Files & Folders",
        "kTCCServiceSystemPolicyAppBundles": "App Management",
        "kTCCServiceAppleEvents": "Automation",
        "kTCCServiceBluetoothAlways": "Bluetooth",
        "kTCCServiceBluetooth": "Bluetooth",
        "kTCCServiceWillow": "Bluetooth",
        "kTCCServiceMotion": "Motion & Fitness",
        "kTCCServiceSpeechRecognition": "Speech Recognition",
        "kTCCServiceSiri": "Speech Recognition",
        "kTCCServiceRemoteDesktop": "Remote Desktop",
        "kTCCServiceFileProviderDomain": "Files & Folders",
        "kTCCServiceFileProviderPresence": "Files & Folders",
        "kTCCServiceUserTracking": "App Management",
        "kTCCServiceFocusStatus": "Focus",
        "kTCCServiceLocalNetwork": "Local Network",
        "kTCCServiceLiverpool": "PassKeys Access",
        "kTCCServiceWebBrowserPublicKeyCredential": "PassKeys Access",
        "kTCCServiceUbiquity": "App Management",
        "kTCCServiceDeveloperTool": "Developer Tools",
        "kTCCServiceEndpointSecurityClient": "Developer Tools"
    ]
    
    private func categoryForService(_ service: String) -> String {
        return serviceCategories[service] ?? "Other"
    }
    
    private var groupedEntries: [String: [TCCUserEntry]] {
        var groups: [String: [TCCUserEntry]] = [:]
        for entry in viewModel.entries {
            let category = categoryForService(entry.service)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append(entry)
        }
        return groups
    }
    
    private var sortedCategories: [String] {
        groupedEntries.keys.sorted()
    }
    
    private func allowedCount(for category: String) -> Int {
        groupedEntries[category]?.filter { $0.auth_value == 2 }.count ?? 0
    }
    
    private func totalCount(for category: String) -> Int {
        groupedEntries[category]?.count ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Compact Header
            VStack(spacing: 8) {
                Text("User TCC Database")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .textSelection(.enabled)
                }
            }
            .padding(.top, 8)
            
            Divider()
            
            // Entries List
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedCategories, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                // Category Header
                                Button(action: {
                                    if expandedCategories.contains(category) {
                                        expandedCategories.remove(category)
                                    } else {
                                        expandedCategories.insert(category)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: expandedCategories.contains(category) ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                        
                                        Text(category)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        Text("\(allowedCount(for: category)) allowed / \(totalCount(for: category)) total")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.secondary.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                
                                // Category Entries
                                if expandedCategories.contains(category) {
                                    ForEach(groupedEntries[category] ?? []) { entry in
                                        entryView(entry)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("TCC User")
        .onAppear {
            if viewModel.entries.isEmpty && !viewModel.isLoading {
                viewModel.loadTCCData()
            }
        }
    }
    
    @ViewBuilder
    private func entryView(_ entry: TCCUserEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header - Always visible, clickable
            Button(action: {
                if expandedEntries.contains(entry.id) {
                    expandedEntries.remove(entry.id)
                } else {
                    expandedEntries.insert(entry.id)
                }
            }) {
                HStack {
                    Image(systemName: expandedEntries.contains(entry.id) ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Image(systemName: "app.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("client: \(entry.client)")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("service: \(entry.service)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Show auth value badge
                    Text(authValueText(entry.auth_value))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(authValueColor(entry.auth_value))
                        .cornerRadius(6)
                }
            }
            .buttonStyle(.plain)
            
            // Expanded details
            if expandedEntries.contains(entry.id) {
                VStack(alignment: .leading, spacing: 4) {
                    fieldRow("client_type", value: "\(entry.client_type)")
                    fieldRow("auth_value", value: "\(entry.auth_value)")
                    fieldRow("auth_reason", value: "\(entry.auth_reason)")
                    fieldRow("auth_version", value: "\(entry.auth_version)")
                    
                    if let csreq = entry.csreq {
                        fieldRow("csreq", value: "\(csreq.count) bytes")
                        
                        if let bundleID = entry.parsedBundleID {
                            fieldRow("  ↳ parsed_bundle_id", value: bundleID)
                        }
                        
                        if let teamID = entry.parsedTeamID {
                            fieldRow("  ↳ parsed_team_id", value: teamID)
                        }
                    } else {
                        fieldRow("csreq", value: "nil")
                    }
                    
                    if let policy_id = entry.policy_id {
                        fieldRow("policy_id", value: "\(policy_id)")
                    } else {
                        fieldRow("policy_id", value: "nil")
                    }
                    
                    if let type = entry.indirect_object_identifier_type {
                        fieldRow("indirect_object_identifier_type", value: "\(type)")
                    } else {
                        fieldRow("indirect_object_identifier_type", value: "nil")
                    }
                    
                    fieldRow("indirect_object_identifier", value: entry.indirect_object_identifier)
                    
                    if let identity = entry.indirect_object_code_identity {
                        fieldRow("indirect_object_code_identity", value: "\(identity.count) bytes")
                    } else {
                        fieldRow("indirect_object_code_identity", value: "nil")
                    }
                    
                    if let flags = entry.flags {
                        fieldRow("flags", value: "\(flags)")
                    } else {
                        fieldRow("flags", value: "nil")
                    }
                    
                    if let last_modified = entry.last_modified {
                        fieldRow("last_modified", value: last_modified.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        fieldRow("last_modified", value: "nil")
                    }
                    
                    if let pid = entry.pid {
                        fieldRow("pid", value: "\(pid)")
                    } else {
                        fieldRow("pid", value: "nil")
                    }
                    
                    if let pid_version = entry.pid_version {
                        fieldRow("pid_version", value: "\(pid_version)")
                    } else {
                        fieldRow("pid_version", value: "nil")
                    }
                    
                    fieldRow("boot_uuid", value: entry.boot_uuid)
                    
                    if let last_reminded = entry.last_reminded {
                        fieldRow("last_reminded", value: last_reminded.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        fieldRow("last_reminded", value: "nil")
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 24)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func fieldRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 200, alignment: .trailing)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func authValueText(_ value: Int) -> String {
        switch value {
        case 0: return "Denied"
        case 2: return "Allowed"
        case 3: return "Limited"
        default: return "Unknown"
        }
    }
    
    private func authValueColor(_ value: Int) -> Color {
        switch value {
        case 0: return .red
        case 2: return .green
        case 3: return .orange
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        TCCUserView()
    }
}
