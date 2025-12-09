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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.client)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let bundleID = entry.bundleID {
                        Text(bundleID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
            
            HStack {
                Label(entry.service, systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Revoked: \(entry.revokedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let teamID = entry.teamID {
                Text("Team ID: \(teamID)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let reason = entry.reason {
                Text("Reason: \(reason)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .italic()
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
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
