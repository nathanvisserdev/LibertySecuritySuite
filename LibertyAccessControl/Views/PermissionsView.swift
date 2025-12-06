//
//  PermissionsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import SwiftUI

struct PermissionsView: View {
    @StateObject private var viewModel = PermissionsViewModel()
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
    
    // Combine and group all entries
    private var allEntriesGrouped: [String: [(entry: Any, source: String)]] {
        var groups: [String: [(entry: Any, source: String)]] = [:]
        
        for entry in viewModel.systemEntries {
            let category = categoryForService(entry.service)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append((entry: entry, source: "System"))
        }
        
        for entry in viewModel.userEntries {
            let category = categoryForService(entry.service)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append((entry: entry, source: "User"))
        }
        
        return groups
    }
    
    private var sortedCategories: [String] {
        allEntriesGrouped.keys.sorted()
    }
    
    private func allowedCount(for category: String) -> Int {
        guard let entries = allEntriesGrouped[category] else { return 0 }
        return entries.filter { item in
            if let systemEntry = item.entry as? TCCSystemEntry {
                return systemEntry.auth_value == 2
            } else if let userEntry = item.entry as? TCCUserEntry {
                return userEntry.auth_value == 2
            }
            return false
        }.count
    }
    
    private func totalCount(for category: String) -> Int {
        allEntriesGrouped[category]?.count ?? 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                
                Text("All Permissions")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(viewModel.statusMessage)
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
                        .textSelection(.enabled)
                }
            }
            
            // Load Button
            Button(action: {
                viewModel.loadTCCData()
            }) {
                Label(viewModel.isLoading ? "Loading..." : "Load All Permissions", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            .padding(.horizontal)
            
            Divider()
            
            // Categorized List
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedCategories, id: \.self) { category in
                            CategorySection(
                                category: category,
                                entries: allEntriesGrouped[category] ?? [],
                                isExpanded: expandedCategories.contains(category),
                                allowedCount: allowedCount(for: category),
                                totalCount: totalCount(for: category),
                                toggleExpansion: {
                                    if expandedCategories.contains(category) {
                                        expandedCategories.remove(category)
                                    } else {
                                        expandedCategories.insert(category)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("Permissions")
    }
}

// MARK: - Category Section View
struct CategorySection: View {
    let category: String
    let entries: [(entry: Any, source: String)]
    let isExpanded: Bool
    let allowedCount: Int
    let totalCount: Int
    let toggleExpansion: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            Button(action: toggleExpansion) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(category)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Count badge
                    HStack(spacing: 4) {
                        Text("\(allowedCount)")
                            .foregroundColor(.green)
                        Text("/")
                            .foregroundColor(.secondary)
                        Text("\(totalCount)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding(12)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            // Entries
            if isExpanded {
                LazyVStack(spacing: 8) {
                    ForEach(entries.indices, id: \.self) { index in
                        let item = entries[index]
                        if let systemEntry = item.entry as? TCCSystemEntry {
                            PermissionEntryView(
                                client: systemEntry.client,
                                service: systemEntry.service,
                                authValue: systemEntry.auth_value,
                                source: item.source,
                                details: systemEntry
                            )
                        } else if let userEntry = item.entry as? TCCUserEntry {
                            PermissionEntryView(
                                client: userEntry.client,
                                service: userEntry.service,
                                authValue: userEntry.auth_value,
                                source: item.source,
                                details: userEntry
                            )
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
    }
}

// MARK: - Permission Entry View
struct PermissionEntryView: View {
    let client: String
    let service: String
    let authValue: Int
    let source: String
    let details: Any
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(client)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(source)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(source == "System" ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(6)
                    
                    Text(authValueText(authValue))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(authValueColor(authValue))
                        .cornerRadius(6)
                }
                .padding(10)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let systemEntry = details as? TCCSystemEntry {
                        systemDetailsView(entry: systemEntry)
                    } else if let userEntry = details as? TCCUserEntry {
                        userDetailsView(entry: userEntry)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.04))
                .cornerRadius(8)
                .padding(.leading, 20)
            }
        }
    }
    
    @ViewBuilder
    private func systemDetailsView(entry: TCCSystemEntry) -> some View {
        detailRow(label: "Service", value: entry.service)
        detailRow(label: "Client", value: entry.client)
        detailRow(label: "Client Type", value: "\(entry.client_type)")
        detailRow(label: "Auth Value", value: "\(entry.auth_value)")
        detailRow(label: "Auth Reason", value: "\(entry.auth_reason)")
        if let csreq = entry.csreq {
            detailRow(label: "Code Signature", value: csreq.map { String(format: "%02x", $0) }.joined())
        }
        if let policyID = entry.policy_id {
            detailRow(label: "Policy ID", value: "\(policyID)")
        }
        detailRow(label: "Indirect Object", value: entry.indirect_object_identifier)
        if let lastModified = entry.last_modified {
            detailRow(label: "Last Modified", value: lastModified.formatted(date: .abbreviated, time: .shortened))
        }
    }
    
    @ViewBuilder
    private func userDetailsView(entry: TCCUserEntry) -> some View {
        detailRow(label: "Service", value: entry.service)
        detailRow(label: "Client", value: entry.client)
        detailRow(label: "Client Type", value: "\(entry.client_type)")
        detailRow(label: "Auth Value", value: "\(entry.auth_value)")
        detailRow(label: "Auth Reason", value: "\(entry.auth_reason)")
        if let csreq = entry.csreq {
            detailRow(label: "Code Signature", value: csreq.map { String(format: "%02x", $0) }.joined())
        }
        if let policyID = entry.policy_id {
            detailRow(label: "Policy ID", value: "\(policyID)")
        }
        detailRow(label: "Indirect Object", value: entry.indirect_object_identifier)
        if let lastModified = entry.last_modified {
            detailRow(label: "Last Modified", value: lastModified.formatted(date: .abbreviated, time: .shortened))
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .fontWeight(.semibold)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
        .font(.caption)
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
    PermissionsView()
}
