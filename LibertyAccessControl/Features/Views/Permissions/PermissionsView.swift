//
//  PermissionsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import SwiftUI

struct PermissionsView: View {
    @StateObject private var viewModel: PermissionsVM
    @State private var expandedCategories: Set<String> = []
    let onNavigate: (AnyView) -> Void
    
    init(onNavigate: @escaping (AnyView) -> Void = { _ in }) {
        let systemService = SystemService()
        let userService = UserService()
        _viewModel = StateObject(wrappedValue: PermissionsVM(systemService: systemService, userService: userService))
        self.onNavigate = onNavigate
    }
    
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
    
    // Group system entries by category
    private var systemEntriesGrouped: [String: [SystemEntry]] {
        var groups: [String: [SystemEntry]] = [:]
        
        for entry in viewModel.systemEntries {
            let category = categoryForService(entry.service)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append(entry)
        }
        
        return groups
    }
    
    // Group user entries by category
    private var userEntriesGrouped: [String: [UserEntry]] {
        var groups: [String: [UserEntry]] = [:]
        
        for entry in viewModel.userEntries {
            let category = categoryForService(entry.service)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append(entry)
        }
        
        return groups
    }
    
    private var sortedSystemCategories: [String] {
        systemEntriesGrouped.keys.sorted()
    }
    
    private var sortedUserCategories: [String] {
        userEntriesGrouped.keys.sorted()
    }
    
    private func allowedCountSystem(for category: String) -> Int {
        guard let entries = systemEntriesGrouped[category] else { return 0 }
        return entries.filter { $0.auth_value == 2 }.count
    }
    
    private func totalCountSystem(for category: String) -> Int {
        systemEntriesGrouped[category]?.count ?? 0
    }
    
    private func allowedCountUser(for category: String) -> Int {
        guard let entries = userEntriesGrouped[category] else { return 0 }
        return entries.filter { $0.auth_value == 2 }.count
    }
    
    private func totalCountUser(for category: String) -> Int {
        userEntriesGrouped[category]?.count ?? 0
    }
    
    private var totalSystemAllowed: Int {
        viewModel.systemEntries.filter { $0.auth_value == 2 }.count
    }
    
    private var totalUserAllowed: Int {
        viewModel.userEntries.filter { $0.auth_value == 2 }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Stats Row
            VStack(spacing: 8) {
                Text("Permissions")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Total: \(viewModel.systemEntries.count + viewModel.userEntries.count), Allowed: \(totalSystemAllowed + totalUserAllowed)")
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
            
            // Categorized List
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // System Permissions Header & Categories
                        if !viewModel.systemEntries.isEmpty {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(.green)
                                Text("System Permissions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("\(totalSystemAllowed) allowed / \(viewModel.systemEntries.count) total")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            ForEach(sortedSystemCategories, id: \.self) { category in
                                SystemCategorySection(
                                    category: category,
                                    entries: systemEntriesGrouped[category] ?? [],
                                    isExpanded: expandedCategories.contains("system-\(category)"),
                                    allowedCount: allowedCountSystem(for: category),
                                    totalCount: totalCountSystem(for: category),
                                    toggleExpansion: {
                                        if expandedCategories.contains("system-\(category)") {
                                            expandedCategories.remove("system-\(category)")
                                        } else {
                                            expandedCategories.insert("system-\(category)")
                                        }
                                    },
                                    viewModel: viewModel
                                )
                            }
                        }
                        
                        // User Permissions Header & Categories
                        if !viewModel.userEntries.isEmpty {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                Text("User Permissions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("\(totalUserAllowed) allowed / \(viewModel.userEntries.count) total")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, viewModel.systemEntries.isEmpty ? 8 : 24)
                            
                            ForEach(sortedUserCategories, id: \.self) { category in
                                UserCategorySection(
                                    category: category,
                                    entries: userEntriesGrouped[category] ?? [],
                                    isExpanded: expandedCategories.contains("user-\(category)"),
                                    allowedCount: allowedCountUser(for: category),
                                    totalCount: totalCountUser(for: category),
                                    toggleExpansion: {
                                        if expandedCategories.contains("user-\(category)") {
                                            expandedCategories.remove("user-\(category)")
                                        } else {
                                            expandedCategories.insert("user-\(category)")
                                        }
                                    },
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("All Permissions")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Button("All") {
                        // Functionality to be added
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(.blue)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("User") {
                        // Functionality to be added
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(.primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("System") {
                        // Functionality to be added
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            if viewModel.systemEntries.isEmpty && viewModel.userEntries.isEmpty && !viewModel.isLoading {
                viewModel.loadTCCData()
            }
        }
    }
}

// MARK: - System Category Section View
struct SystemCategorySection: View {
    let category: String
    let entries: [SystemEntry]
    let isExpanded: Bool
    let allowedCount: Int
    let totalCount: Int
    let toggleExpansion: () -> Void
    let viewModel: PermissionsVM
    
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
                    ForEach(entries) { entry in
                        PermissionEntryView(
                            client: entry.client,
                            service: entry.service,
                            authValue: entry.auth_value,
                            source: "System",
                            details: entry,
                            viewModel: viewModel
                        )
                    }
                }
                .padding(.leading, 32)
            }
        }
    }
}

// MARK: - User Category Section View
struct UserCategorySection: View {
    let category: String
    let entries: [UserEntry]
    let isExpanded: Bool
    let allowedCount: Int
    let totalCount: Int
    let toggleExpansion: () -> Void
    let viewModel: PermissionsVM
    
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
                    ForEach(entries) { entry in
                        PermissionEntryView(
                            client: entry.client,
                            service: entry.service,
                            authValue: entry.auth_value,
                            source: "User",
                            details: entry,
                            viewModel: viewModel
                        )
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
    let viewModel: PermissionsVM
    
    @State private var isExpanded = false
    @State private var isEnabled: Bool
    @State private var statusMessage: String?
    @State private var isSuccess: Bool = true
    
    init(client: String, service: String, authValue: Int, source: String, details: Any, viewModel: PermissionsVM) {
        self.client = client
        self.service = service
        self.authValue = authValue
        self.source = source
        self.details = details
        self.viewModel = viewModel
        self._isEnabled = State(initialValue: authValue == 2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
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
                    }
                }
                .buttonStyle(.plain)
                
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: isEnabled) { oldValue, newValue in
                        let newAuthValue = newValue ? 2 : 0
                        let isSystemDB = (source == "System")
                        
                        statusMessage = "Updating..."
                        isSuccess = true
                        
                        viewModel.updatePermission(
                            service: service,
                            client: client,
                            authValue: newAuthValue,
                            isSystemDB: isSystemDB
                        ) { success, message in
                            isSuccess = success
                            statusMessage = message
                            
                            if !success {
                                // Revert toggle on failure
                                isEnabled = oldValue
                            }
                            
                            // Clear message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                statusMessage = nil
                            }
                        }
                    }
                
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
            
            // Status message
            if let message = statusMessage {
                Text(isSuccess ? "Success: \(message)" : "Failure: \(message)")
                    .font(.caption)
                    .foregroundColor(isSuccess ? .green : .red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .padding(.leading, 20)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let systemEntry = details as? SystemEntry {
                        systemDetailsView(entry: systemEntry)
                    } else if let userEntry = details as? UserEntry {
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
    private func systemDetailsView(entry: SystemEntry) -> some View {
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
    private func userDetailsView(entry: UserEntry) -> some View {
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
