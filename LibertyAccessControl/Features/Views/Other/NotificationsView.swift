//
//  NotificationsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var viewModel: NotificationsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: viewModel.isNotificationsEnabled ? "bell.badge.fill" : "bell.badge")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.isNotificationsEnabled ? .blue : .gray)
                
                Text("Notifications Monitoring")
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
                        .padding(.horizontal)
                }
            }
            
            Divider()
            
            // Access requests log
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Notifications")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.accessRequests.isEmpty {
                    Text("No New Notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.accessRequests) { request in
                                ExpandableRequestRow(request: request)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Notifications")
    }
}

struct ExpandableRequestRow: View {
    let request: TCCAccessRequest
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(request.processName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(request.decision)
                                .font(.caption)
                                .foregroundColor(request.decision.contains("✓") ? .green : request.decision.contains("✗") ? .red : .orange)
                        }
                        
                        Text(request.serviceName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(request.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            // Expanded details
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notification Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    
                    ForEach(Array(request.parsedDetails.keys.sorted()), id: \.self) { key in
                        if let value = request.parsedDetails[key] {
                            HStack(alignment: .top, spacing: 8) {
                                Text(key)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(value)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Raw Log Line")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    
                    Text(request.rawLogLine)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(4)
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color(nsColor: .systemGray).opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environmentObject(NotificationsViewModel.shared)
    }
}
