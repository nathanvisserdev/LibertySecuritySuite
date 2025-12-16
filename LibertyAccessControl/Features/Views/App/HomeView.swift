//
//  HomeView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI
import Combine

struct SystemMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: MessageType
    
    enum MessageType {
        case success
        case info
        case warning
        case error
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
}

class SystemMessageService: ObservableObject {
    static let shared = SystemMessageService()
    
    @Published var messages: [SystemMessage] = []
    private let maxMessages = 100
    
    private init() {
        // Listen for console output notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSystemLog(_:)),
            name: NSNotification.Name("SystemLogMessage"),
            object: nil
        )
    }
    
    func addMessage(_ text: String, type: SystemMessage.MessageType = .info) {
        DispatchQueue.main.async {
            let message = SystemMessage(timestamp: Date(), message: text, type: type)
            self.messages.insert(message, at: 0)
            
            // Keep only recent messages
            if self.messages.count > self.maxMessages {
                self.messages.removeLast()
            }
        }
    }
    
    @objc private func handleSystemLog(_ notification: Notification) {
        if let message = notification.userInfo?["message"] as? String,
           let type = notification.userInfo?["type"] as? SystemMessage.MessageType {
            addMessage(message, type: type)
        }
    }
    
    func clearMessages() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
}

struct HomeView: View {
    @StateObject private var messageService = SystemMessageService.shared
    @StateObject private var malwareScanner = MalwareScannerService.shared
    @State private var searchText = ""
    @State private var databaseStatuses: [DatabaseStatus] = []
    @State private var showDatabaseDetails = false
    @State private var showMalwareDetails = false
    
    var filteredMessages: [SystemMessage] {
        if searchText.isEmpty {
            return messageService.messages
        }
        return messageService.messages.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Liberty Access Control")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("System Activity Monitor")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showDatabaseDetails.toggle() }) {
                        Label("Database Status", systemImage: "externaldrive.fill")
                    }
                    
                    Button(action: {
                        messageService.clearMessages()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                }
                .padding()
                
                // Status cards
                HStack(spacing: 12) {
                    // Malware scan status
                    StatusCard(
                        icon: malwareScanner.lastScanResult?.isClean == true ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                        iconColor: malwareScanner.lastScanResult?.isClean == true ? .green : .red,
                        title: "Malware Status",
                        subtitle: malwareScanStatusText,
                        action: { showMalwareDetails = true }
                    )
                    
                    // Database integrity status
                    StatusCard(
                        icon: "externaldrive.fill",
                        iconColor: .blue,
                        title: "Database Status",
                        subtitle: "\(databaseStatuses.filter { $0.exists }.count) of \(databaseStatuses.count) active",
                        action: { showDatabaseDetails = true }
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search messages...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Messages list
            if filteredMessages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No system messages yet" : "No matching messages")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("System events and notifications will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredMessages) { message in
                            MessageRow(message: message)
                        }
                    }
                }
            }
        }
        .onAppear {
            checkDatabases()
        }
        .sheet(isPresented: $showDatabaseDetails) {
            DatabaseStatusSheet(statuses: databaseStatuses)
        }
        .sheet(isPresented: $showMalwareDetails) {
            MalwareStatusSheet(scanResult: malwareScanner.lastScanResult)
        }
    }
    
    private var malwareScanStatusText: String {
        if malwareScanner.isScanning {
            return "Scanning... \(Int(malwareScanner.currentScanProgress * 100))%"
        } else if let result = malwareScanner.lastScanResult {
            if result.isClean {
                return "Clean - \(result.filesScanned) files scanned"
            } else {
                return "⚠️ \(result.threatsDetected) threats quarantined"
            }
        } else {
            return "No scan performed yet"
        }
    }
    
    private func checkDatabases() {
        databaseStatuses = DatabaseStatusService.shared.checkAllDatabases()
        
        // Add initialization messages
        let initMessages = DatabaseStatusService.shared.initializeDatabases()
        for message in initMessages {
            messageService.addMessage(message, type: .success)
        }
        
        // Add database status messages
        for status in databaseStatuses {
            let statusMessage = status.exists 
                ? "✅ \(status.name): Found at \(status.location)"
                : "⚠️ \(status.name): Will be created on first use"
            
            messageService.addMessage(statusMessage, type: status.exists ? .success : .warning)
        }
        
        // Add welcome message if this is first launch
        if messageService.messages.count == databaseStatuses.count + initMessages.count {
            messageService.addMessage("Welcome to Liberty Access Control", type: .info)
        }
    }
}

struct MessageRow: View {
    let message: SystemMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.type.icon)
                .foregroundColor(message.type.color)
                .font(.system(size: 16))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.message)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Database Status Sheet

struct DatabaseStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    let statuses: [DatabaseStatus]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Database Status")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(statuses, id: \.name) { status in
                        DatabaseStatusRow(status: status)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct DatabaseStatusRow: View {
    let status: DatabaseStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: status.exists ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(status.exists ? .green : .orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.name)
                        .font(.headline)
                    
                    Text(status.exists ? "Database found" : "Database will be created on first use")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let size = status.size {
                    Text(size)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Location:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(status.location)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
            }
            
            HStack {
                Label(typeLabel, systemImage: typeIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var typeLabel: String {
        switch status.type {
        case .coreData: return "Core Data SQLite"
        case .encrypted: return "Encrypted UserDefaults"
        case .userDefaults: return "UserDefaults"
        }
    }
    
    private var typeIcon: String {
        switch status.type {
        case .coreData: return "cylinder.fill"
        case .encrypted: return "lock.fill"
        case .userDefaults: return "doc.fill"
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(subtitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Malware Status Sheet

struct MalwareStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    let scanResult: MalwareScanResult?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Malware Scan Status")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            if let result = scanResult {
                ScrollView {
                    VStack(spacing: 20) {
                        // Status indicator
                        VStack(spacing: 12) {
                            Image(systemName: result.isClean ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .font(.system(size: 64))
                                .foregroundColor(result.isClean ? .green : .red)
                            
                            Text(result.isClean ? "System Clean" : "Threats Detected")
                                .font(.title)
                            
                            Text(result.scanEndTime.formatted())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Statistics
                        HStack(spacing: 20) {
                            MalwareStatBox(label: "Files Scanned", value: "\(result.filesScanned)", icon: "doc.text")
                            MalwareStatBox(label: "Threats Found", value: "\(result.threatsDetected)", icon: "exclamationmark.triangle.fill", color: result.threatsDetected > 0 ? .red : .green)
                            MalwareStatBox(label: "Duration", value: formatDuration(result.duration), icon: "clock")
                        }
                        .padding(.horizontal)
                        
                        // Threat list
                        if !result.quarantinedFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quarantined Threats")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(result.quarantinedFiles) { file in
                                    ThreatSummaryRow(file: file)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No scan performed yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("A full system scan will run at boot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

struct MalwareStatBox: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ThreatSummaryRow: View {
    let file: QuarantinedFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(URL(fileURLWithPath: file.originalPath).lastPathComponent)
                    .font(.body)
                Text(file.threat.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}

