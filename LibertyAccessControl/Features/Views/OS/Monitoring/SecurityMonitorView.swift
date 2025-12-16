//
//  SecurityMonitorView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import SwiftUI

struct SecurityMonitorView: View {
    @StateObject private var monitor = SecurityMonitor()
    @State private var showingThreatDetails: SecurityThreat?
    @State private var selectedSeverityFilter: ThreatSeverity?
    @State private var scanInterval: TimeInterval = 300 // 5 minutes
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Monitor")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Monitors critical system areas for suspicious activity and tampering")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Label(monitor.statusMessage, systemImage: statusIcon)
                        .font(.caption)
                        .foregroundColor(statusColor)
                    
                    if let lastScan = monitor.lastScanDate {
                        Text("Last scan: \(lastScan, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if monitor.isMonitoring {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Active")
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
            
            // Control Panel
            HStack(spacing: 12) {
                if !monitor.isMonitoring {
                    Button(action: {
                        monitor.startMonitoring(interval: scanInterval)
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
                
                Button(action: {
                    monitor.performSecurityScan()
                }) {
                    Label("Scan Now", systemImage: "magnifyingglass")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                
                Picker("Scan Interval", selection: $scanInterval) {
                    Text("1 min").tag(TimeInterval(60))
                    Text("5 min").tag(TimeInterval(300))
                    Text("15 min").tag(TimeInterval(900))
                    Text("30 min").tag(TimeInterval(1800))
                    Text("1 hour").tag(TimeInterval(3600))
                }
                .pickerStyle(.menu)
                .font(.caption)
                
                Spacer()
                
                // Severity Filter
                Picker("Filter", selection: $selectedSeverityFilter) {
                    Text("All").tag(nil as ThreatSeverity?)
                    Text("Critical").tag(ThreatSeverity.critical as ThreatSeverity?)
                    Text("High").tag(ThreatSeverity.high as ThreatSeverity?)
                    Text("Medium").tag(ThreatSeverity.medium as ThreatSeverity?)
                    Text("Low").tag(ThreatSeverity.low as ThreatSeverity?)
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
            .padding()
            
            Divider()
            
            // Threat Statistics
            if !monitor.threats.isEmpty {
                HStack(spacing: 20) {
                    ThreatStatBadge(count: threatCount(for: .critical), severity: .critical)
                    ThreatStatBadge(count: threatCount(for: .high), severity: .high)
                    ThreatStatBadge(count: threatCount(for: .medium), severity: .medium)
                    ThreatStatBadge(count: threatCount(for: .low), severity: .low)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
            
            Divider()
            
            // Threats List
            if monitor.threats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: monitor.lastScanDate == nil ? "shield" : "checkmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(monitor.lastScanDate == nil ? .secondary : .green)
                    
                    Text(monitor.lastScanDate == nil ? "No scan performed yet" : "No threats detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if monitor.lastScanDate == nil {
                        Text("Click 'Scan Now' or 'Start Monitoring' to begin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredThreats) { threat in
                            ThreatRow(threat: threat, onQuarantine: {
                                monitor.quarantineThreat(threat)
                            }, onDelete: {
                                monitor.deleteThreat(threat)
                            }, onIgnore: {
                                monitor.ignoreThreat(threat)
                            }, onShowDetails: {
                                showingThreatDetails = threat
                            })
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                }
            }
        }
        .sheet(item: $showingThreatDetails) { threat in
            ThreatDetailsView(threat: threat)
        }
    }
    
    private var filteredThreats: [SecurityThreat] {
        guard let severity = selectedSeverityFilter else {
            return monitor.threats
        }
        return monitor.threats.filter { $0.severity == severity }
    }
    
    private func threatCount(for severity: ThreatSeverity) -> Int {
        monitor.threats.filter { $0.severity == severity }.count
    }
    
    private var statusIcon: String {
        if monitor.threats.isEmpty {
            return monitor.lastScanDate == nil ? "shield" : "checkmark.shield"
        } else {
            return "exclamationmark.shield"
        }
    }
    
    private var statusColor: Color {
        if monitor.threats.isEmpty {
            return monitor.lastScanDate == nil ? .secondary : .green
        } else {
            return .orange
        }
    }
}

struct ThreatStatBadge: View {
    let count: Int
    let severity: ThreatSeverity
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            
            Text(severity.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var color: Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct ThreatRow: View {
    let threat: SecurityThreat
    let onQuarantine: () -> Void
    let onDelete: () -> Void
    let onIgnore: () -> Void
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Severity Indicator
                VStack {
                    Image(systemName: iconForThreatType(threat.type))
                        .font(.system(size: 24))
                        .foregroundColor(colorForSeverity(threat.severity))
                        .frame(width: 32)
                    
                    Text(threat.severity.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(colorForSeverity(threat.severity))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Threat Type
                    HStack {
                        Text(threat.type.rawValue)
                            .font(.headline)
                            .foregroundColor(colorForSeverity(threat.severity))
                        
                        Spacer()
                        
                        Text(threat.detectedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    Text(threat.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(threat.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    // Details Preview
                    if !threat.details.isEmpty {
                        Text(threat.details.prefix(100) + (threat.details.count > 100 ? "..." : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 6) {
                    Button(action: onQuarantine) {
                        VStack(spacing: 2) {
                            Image(systemName: "shippingbox")
                            Text("Quarantine")
                                .font(.caption2)
                        }
                        .frame(minWidth: 80)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onDelete) {
                        VStack(spacing: 2) {
                            Image(systemName: "trash")
                            Text("Delete")
                                .font(.caption2)
                        }
                        .frame(minWidth: 80)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button(action: onIgnore) {
                        VStack(spacing: 2) {
                            Image(systemName: "eye.slash")
                            Text("Ignore")
                                .font(.caption2)
                        }
                        .frame(minWidth: 80)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onShowDetails) {
                        VStack(spacing: 2) {
                            Image(systemName: "info.circle")
                            Text("Details")
                                .font(.caption2)
                        }
                        .frame(minWidth: 80)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
    
    private func iconForThreatType(_ type: ThreatType) -> String {
        switch type {
        case .suspiciousLaunchAgent:
            return "externaldrive.badge.exclamationmark"
        case .suspiciousFile:
            return "doc.badge.exclamationmark"
        case .unauthorizedExecutable:
            return "terminal.fill"
        case .suspiciousProcess:
            return "cpu"
        case .unauthorizedTCCEntry:
            return "lock.shield"
        case .suspiciousKernelExtension:
            return "puzzlepiece.extension"
        case .tampering:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ThreatSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct ThreatDetailsView: View {
    let threat: SecurityThreat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Threat Details")
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Severity
                    DetailRow(label: "Severity", value: threat.severity.rawValue)
                    
                    // Type
                    DetailRow(label: "Type", value: threat.type.rawValue)
                    
                    // Detected
                    DetailRow(label: "Detected", value: threat.detectedAt.formatted())
                    
                    // Location
                    DetailRow(label: "Location", value: threat.location)
                    
                    // Description
                    DetailRow(label: "Description", value: threat.description)
                    
                    // Full Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                        
                        Text(threat.details)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    SecurityMonitorView()
        .frame(width: 900, height: 700)
}
