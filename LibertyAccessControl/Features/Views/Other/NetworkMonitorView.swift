//
//  NetworkMonitorView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import SwiftUI

struct NetworkMonitorView: View {
    @StateObject private var monitor = NetworkMonitor()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingBlockIPSheet = false
    @State private var ipToBlock = ""
    @State private var showingAuthPrompt = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Network & Firewall Monitor")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Monitor network connections and manage firewall rules")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Label(monitor.statusMessage, systemImage: statusIcon)
                        .font(.caption)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    // Authorization status
                    if !monitor.isAuthorized {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Not Authorized")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Firewall status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(monitor.firewallEnabled ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text("Firewall: \(monitor.firewallEnabled ? "Enabled" : "Disabled")")
                            .font(.caption)
                            .foregroundColor(monitor.firewallEnabled ? .green : .red)
                    }
                    
                    if monitor.isMonitoring {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Monitoring")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Authorization Prompt
            if !monitor.isAuthorized {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Biometric Authorization Required")
                        .font(.headline)
                    
                    Text("Firewall management requires biometric authentication.\nUse Touch ID or Face ID to authorize.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        monitor.requestAuthorization()
                    }) {
                        Label("Authenticate with Biometrics", systemImage: "faceid")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Control Panel
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                if !monitor.isMonitoring {
                    Button(action: {
                        monitor.startMonitoring()
                    }) {
                        Label("Start Monitoring", systemImage: "play.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        monitor.stopMonitoring()
                    }) {
                        Label("Stop Monitoring", systemImage: "stop.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                
                if !monitor.firewallEnabled {
                    Button(action: {
                        monitor.enableFirewall()
                    }) {
                        Label("Enable Firewall", systemImage: "shield.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(action: {
                        monitor.disableFirewall()
                    }) {
                        Label("Disable Firewall", systemImage: "shield.slash")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                
                Button(action: {
                    showingBlockIPSheet = true
                }) {
                    Label("Block IP", systemImage: "hand.raised.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Active (\(monitor.activeConnections.count))").tag(0)
                Text("Blocked (\(monitor.blockedConnections.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
            
            // Content
            if selectedTab == 0 {
                activeConnectionsView
            } else {
                blockedConnectionsView
            }
                }
            }
        }
        .sheet(isPresented: $showingBlockIPSheet) {
            BlockIPSheet(ipToBlock: $ipToBlock, onBlock: {
                monitor.blockIP(ipToBlock)
                showingBlockIPSheet = false
                ipToBlock = ""
            })
        }
    }
    
    // MARK: - Active Connections View
    
    private var activeConnectionsView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search connections...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 1) {
                    if filteredActiveConnections.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: monitor.isMonitoring ? "wifi.slash" : "network")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text(monitor.isMonitoring ? "No active connections" : "Start monitoring to view connections")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(filteredActiveConnections) { connection in
                            ConnectionRow(connection: connection, onBlock: {
                                monitor.blockIP(connection.remoteAddress)
                            })
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Blocked Connections View
    
    private var blockedConnectionsView: some View {
        VStack(spacing: 8) {
            if !monitor.blockedConnections.isEmpty {
                HStack {
                    Spacer()
                    Button(action: {
                        monitor.clearBlockedConnections()
                    }) {
                        Label("Clear All", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if monitor.blockedConnections.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            Text("No Blocked Connections")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Suspicious connections will be blocked and logged here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(monitor.blockedConnections) { blocked in
                            BlockedConnectionRow(blockedConnection: blocked, onUnblock: {
                                monitor.unblockIP(blocked.connection.remoteAddress)
                            })
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredActiveConnections: [NetworkConnection] {
        guard !searchText.isEmpty else {
            return monitor.activeConnections
        }
        
        return monitor.activeConnections.filter {
            $0.processName.localizedCaseInsensitiveContains(searchText) ||
            $0.remoteAddress.contains(searchText) ||
            $0.bundleID?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    private var statusIcon: String {
        if !monitor.isMonitoring {
            return "pause.circle"
        }
        return monitor.blockedConnections.isEmpty ? "checkmark.circle" : "exclamationmark.triangle"
    }
    
    private var statusColor: Color {
        if !monitor.isMonitoring {
            return .secondary
        }
        return monitor.blockedConnections.isEmpty ? .green : .orange
    }
}

// MARK: - Connection Row

struct ConnectionRow: View {
    let connection: NetworkConnection
    let onBlock: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Direction indicator
            Image(systemName: connection.direction == .outbound ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(connection.direction == .outbound ? .blue : .green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                // Process name
                HStack {
                    Text(connection.processName)
                        .font(.headline)
                    
                    Text("PID: \(connection.processID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Bundle ID if available
                if let bundleID = connection.bundleID {
                    Text(bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Connection details
                HStack(spacing: 4) {
                    Image(systemName: "network")
                        .font(.caption2)
                    Text("\(connection.protocol) • \(connection.remoteAddress):\(connection.remotePort)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // State
                Text(connection.state)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(stateColor(connection.state))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 6) {
                Button(action: onBlock) {
                    VStack(spacing: 2) {
                        Image(systemName: "hand.raised.fill")
                        Text("Block")
                            .font(.caption2)
                    }
                    .frame(minWidth: 60)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Text(connection.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func stateColor(_ state: String) -> Color {
        switch state.uppercased() {
        case "ESTABLISHED":
            return .green
        case "LISTEN", "LISTENING":
            return .blue
        case "TIME_WAIT", "CLOSE_WAIT":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Blocked Connection Row

struct BlockedConnectionRow: View {
    let blockedConnection: BlockedConnection
    let onUnblock: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(blockedConnection.connection.processName)
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(blockedConnection.reason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "network")
                        .font(.caption2)
                    Text("\(blockedConnection.connection.remoteAddress):\(blockedConnection.connection.remotePort)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Blocked: \(blockedConnection.blockedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onUnblock) {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle")
                    Text("Unblock")
                        .font(.caption2)
                }
                .frame(minWidth: 60)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Block IP Sheet

struct BlockIPSheet: View {
    @Binding var ipToBlock: String
    let onBlock: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Block IP Address")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Enter IP address", text: $ipToBlock)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Block") {
                    onBlock()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(ipToBlock.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

#Preview {
    NetworkMonitorView()
        .frame(width: 900, height: 700)
}
