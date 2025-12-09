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
    @State private var searchText = ""
    
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
                    
                    Button(action: {
                        messageService.clearMessages()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                }
                .padding()
                
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
            // Add welcome message if empty
            if messageService.messages.isEmpty {
                messageService.addMessage("Welcome to Liberty Access Control", type: .info)
            }
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

#Preview {
    HomeView()
}
