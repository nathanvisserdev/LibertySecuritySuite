//
//  SystemView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct SystemView: View {
    @StateObject private var viewModel = SystemVM()
    @StateObject private var blacklistService = BlacklistService.shared
    @State private var expandedEntries: Set<UUID> = []
    @State private var expandedCategories: Set<String> = []
    @State private var showingRevokeAlert = false
    @State private var entryToRevoke: SystemEntry?
    @State private var revokeReason: String = ""
    
    private let serviceCategories = [
        ("Calendar", ["Calendar"]),
        ("Contacts", ["Contacts", "AddressBook"]),
        ("Files & Folders", ["SystemPolicyDesktopFolder", "SystemPolicyDocumentsFolder", "SystemPolicyDownloadsFolder", "SystemPolicyNetworkVolumes", "SystemPolicyRemovableVolumes"]),
        ("Full Disk Access", ["SystemPolicyAllFiles"]),
        ("Accessibility", ["Accessibility"]),
        ("Bluetooth", ["Bluetooth"]),
        ("Camera", ["Camera"]),
        ("Focus", ["Focus"]),
        ("Microphone", ["Microphone"]),
        ("Photos", ["Photos"]),
        ("Reminders", ["Reminders"]),
        ("Screen Recording", ["ScreenCapture"]),
        ("Location", ["Location"]),
        ("Speech Recognition", ["SpeechRecognition"])
    ]
    
    private func entriesForCategory(_ keywords: [String]) -> [SystemEntry] {
        viewModel.entries.filter { entry in
            keywords.contains(where: { entry.service.contains($0) })
        }
    }
    
    private var allowedCount: Int {
        viewModel.entries.filter { $0.auth_value == 2 }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            VStack(spacing: 8) {
                Text("System Permissions")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Total: \(viewModel.entries.count), Allowed: \(allowedCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
                        ForEach(serviceCategories, id: \.0) { category in
                            let entries = entriesForCategory(category.1)
                            
                            if !entries.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Category Header - Expandable
                                    Button(action: {
                                        if expandedCategories.contains(category.0) {
                                            expandedCategories.remove(category.0)
                                        } else {
                                            expandedCategories.insert(category.0)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: expandedCategories.contains(category.0) ? "chevron.down" : "chevron.right")
                                                .foregroundColor(.secondary)
                                                .frame(width: 20)
                                            
                                            Text(category.0)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                            
                                            Spacer()
                                            
                                            // Count badge
                                            HStack(spacing: 4) {
                                                Text("\(entries.filter { $0.auth_value == 2 }.count)")
                                                    .foregroundColor(.green)
                                                Text("/")
                                                    .foregroundColor(.secondary)
                                                Text("\(entries.count)")
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
                                    
                                    // Category Entries - Only shown when expanded
                                    if expandedCategories.contains(category.0) {
                                        ForEach(entries) { entry in
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Header - Always visible, clickable
                                            HStack {
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
                                                            .frame(width: 20)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("Client: \(entry.client)")
                                                                .fontWeight(.semibold)
                                                            
                                                            Text("Service: \(entry.service)")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                            
                                                            // Show if blacklisted
                                                            if blacklistService.isBlacklisted(service: entry.service, client: entry.client) {
                                                                HStack(spacing: 4) {
                                                                    Image(systemName: "hand.raised.fill")
                                                                    Text("BLACKLISTED")
                                                                }
                                                                .font(.caption2)
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.red)
                                                            }
                                                        }
                                                        
                                                        Spacer()
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                                
                                                // Revoke Button - only show if allowed
                                                if entry.auth_value == 2 {
                                                    Button(action: {
                                                        entryToRevoke = entry
                                                        showingRevokeAlert = true
                                                    }) {
                                                        Image(systemName: "xmark.shield.fill")
                                                            .foregroundColor(.red)
                                                            .font(.system(size: 18))
                                                    }
                                                    .buttonStyle(.plain)
                                                    .help("Revoke and Blacklist")
                                                }
                                                
                                                // Toggle Switch (read-only, shows permission state)
                                                Toggle("", isOn: .constant(entry.auth_value == 2))
                                                    .toggleStyle(.switch)
                                                    .labelsHidden()
                                                    .disabled(true)
                                                
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
                                            .padding(10)
                                            .background(Color.gray.opacity(0.08))
                                            .cornerRadius(8)
                                            
                                            // Expanded details
                                            if expandedEntries.contains(entry.id) {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    fieldRow("service", value: entry.service)
                                                    fieldRow("client", value: entry.client)
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
                                                .padding(10)
                                                .background(Color.gray.opacity(0.04))
                                                .cornerRadius(8)
                                                .padding(.leading, 20)
                                            }
                                        }
                                        }
                                        .padding(.leading, 32)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("System Permissions")
        .alert("Revoke and Blacklist Permission", isPresented: $showingRevokeAlert) {
            Button("Cancel", role: .cancel) {
                entryToRevoke = nil
                revokeReason = ""
            }
            Button("Revoke", role: .destructive) {
                if let entry = entryToRevoke {
                    revokePermission(entry: entry)
                }
            }
        } message: {
            if let entry = entryToRevoke {
                Text("Are you sure you want to revoke \(entry.client)'s access to \(entry.service)? This will blacklist the app and prevent it from regaining this permission. Note: Requires root privileges.")
            }
        }
        .onAppear {
            if viewModel.entries.isEmpty && !viewModel.isLoading {
                viewModel.loadTCCData()
            }
        }
    }
    
    private func revokePermission(entry: SystemEntry) {
        SystemService.shared.revokeAndBlacklistPermission(
            service: entry.service,
            client: entry.client,
            bundleID: entry.parsedBundleID,
            teamID: entry.parsedTeamID,
            reason: revokeReason.isEmpty ? nil : revokeReason
        ) { success, message in
            if success {
                print("✅ System permission revoked and blacklisted: \(message)")
                viewModel.loadTCCData() // Refresh the list
            } else {
                print("❌ Failed to revoke system permission: \(message)")
            }
            entryToRevoke = nil
            revokeReason = ""
        }
    }
    
    private func fieldRow(_ label: String, value: String) -> some View {
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
    
    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        SystemView()
    }
}
