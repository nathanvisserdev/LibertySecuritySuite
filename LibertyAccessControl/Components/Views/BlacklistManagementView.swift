//
//  BlacklistManagementView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct BlacklistManagementView: View {
    @StateObject private var blacklistService = BlacklistService.shared
    @StateObject private var enforcementService = BlacklistEnforcementService.shared
    @State private var selectedTab = 0
    @State private var showingClearAttemptsAlert = false
    @State private var searchText = ""
    @State private var isScanning = false
    @State private var suspiciousApps: [SuspiciousApp] = []
    @State private var showingSuspiciousAlert = false
    
    private let scanner = SuspiciousPermissionScanner()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Blacklist Management")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    // Monitoring toggle
                    HStack {
                        Toggle("Auto-Enforce", isOn: Binding(
                            get: { enforcementService.isMonitoring },
                            set: { isOn in
                                if isOn {
                                    enforcementService.startMonitoring()
                                } else {
                                    enforcementService.stopMonitoring()
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                        
                        if enforcementService.isMonitoring {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Scan button
                    Button(action: scanForSuspiciousApps) {
                        HStack {
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "magnifyingglass.circle.fill")
                            }
                            Text(isScanning ? "Scanning..." : "Scan Now")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning)
                }
            }
            .padding()
            
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Blacklist (\(blacklistService.blacklistedEntries.count))").tag(0)
                Text("Attempts (\(blacklistService.revocationAttempts.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
            
            // Content
            if selectedTab == 0 {
                blacklistView
            } else {
                attemptsView
            }
        }
        .navigationTitle("Blacklist Management")
        .onAppear {
            // Start monitoring by default
            if !enforcementService.isMonitoring {
                enforcementService.startMonitoring()
            }
        }
        .alert("Suspicious Apps Detected", isPresented: $showingSuspiciousAlert) {
            Button("Cancel", role: .cancel) {
                suspiciousApps = []
            }
            Button("Blacklist All", role: .destructive) {
                autoBlacklistSuspicious()
            }
        } message: {
            Text("Found \(suspiciousApps.count) app(s) with unauthorized permissions. Do you want to automatically blacklist them?")
        }
    }
    
    // MARK: - Scan Methods
    
    private func scanForSuspiciousApps() {
        isScanning = true
        
        scanner.scanAllDatabases { found in
            isScanning = false
            suspiciousApps = found
            
            if !found.isEmpty {
                showingSuspiciousAlert = true
            }
        }
    }
    
    private func autoBlacklistSuspicious() {
        scanner.autoBlacklistSuspiciousApps(suspiciousApps: suspiciousApps) { count in
            print("✅ Auto-blacklisted \(count) suspicious apps")
            suspiciousApps = []
        }
    }
    
    // MARK: - Blacklist View
    
    private var blacklistView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if blacklistService.blacklistedEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("No Blacklisted Permissions")
                            .font(.headline)
                        Text("Revoked permissions will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filteredBlacklist) { entry in
                        blacklistEntryCard(entry)
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search blacklist...")
    }
    
    private var filteredBlacklist: [BlacklistEntry] {
        if searchText.isEmpty {
            return blacklistService.blacklistedEntries
        }
        return blacklistService.blacklistedEntries.filter { entry in
            entry.client.localizedCaseInsensitiveContains(searchText) ||
            entry.service.localizedCaseInsensitiveContains(searchText) ||
            (entry.bundleID?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private func blacklistEntryCard(_ entry: BlacklistEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(entry.bundleID ?? entry.client)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if entry.wasAutomaticallyBlacklisted {
                            Text("AUTO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(entry.client)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    blacklistService.removeFromBlacklist(id: entry.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // All Revoked Services
            VStack(alignment: .leading, spacing: 6) {
                Text("Revoked Permissions (\(entry.allRevokedServices.count))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(entry.allRevokedServices, id: \.self) { service in
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(service)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Banned: \(entry.revokedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let teamID = entry.teamID {
                    HStack {
                        Image(systemName: "person.badge.key")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Team ID: \(teamID)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Access attempts count
                let attemptCount = blacklistService.revocationAttempts.filter { 
                    $0.client == entry.client 
                }.count
                
                if attemptCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(attemptCount) access attempt\(attemptCount == 1 ? "" : "s") blocked")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if let reason = entry.reason {
                Divider()
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .italic()
                }
            }
        }
        .padding()
        .background(entry.wasAutomaticallyBlacklisted ? Color.orange.opacity(0.05) : Color.red.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(entry.wasAutomaticallyBlacklisted ? Color.orange.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Attempts View
    
    private var attemptsView: some View {
        VStack(spacing: 8) {
            // Clear button
            if !blacklistService.revocationAttempts.isEmpty {
                HStack {
                    Spacer()
                    Menu {
                        Button("Clear All") {
                            showingClearAttemptsAlert = true
                        }
                        Button("Clear Older than 7 days") {
                            blacklistService.clearOldAttempts(olderThan: 7)
                        }
                        Button("Clear Older than 30 days") {
                            blacklistService.clearOldAttempts(olderThan: 30)
                        }
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if blacklistService.revocationAttempts.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Attempts Logged")
                                .font(.headline)
                            Text("Permission re-grant attempts will appear here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(blacklistService.revocationAttempts) { attempt in
                            attemptCard(attempt)
                        }
                    }
                }
                .padding()
            }
        }
        .alert("Clear All Attempts", isPresented: $showingClearAttemptsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                blacklistService.clearAttempts()
            }
        } message: {
            Text("Are you sure you want to clear all revocation attempts from the log?")
        }
    }
    
    private func attemptCard(_ attempt: RevocationAttempt) -> some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: attempt.blocked ? "hand.raised.fill" : "checkmark.circle.fill")
                .foregroundColor(attempt.blocked ? .red : .orange)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(attempt.client)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let bundleID = attempt.bundleID {
                    Text(bundleID)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(attempt.service)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(attempt.attemptedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status badge
            Text(attempt.blocked ? "BLOCKED" : "LOGGED")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(attempt.blocked ? Color.red : Color.orange)
                .cornerRadius(6)
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        BlacklistManagementView()
    }
}
