//
//  ReqMonView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct ReqMonView: View {
    @StateObject private var viewModel = ReqMonVM()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: viewModel.isNotificationsEnabled ? "bell.badge.fill" : "bell.badge")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.isNotificationsEnabled ? .blue : .gray)
                
                Text("Request Monitoring")
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
            
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.requestNotificationPermission()
                    viewModel.enableMonitoring()
                }) {
                    Label("Enable Monitoring", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.isNotificationsEnabled)
                
                Button(action: {
                    viewModel.disableMonitoring()
                }) {
                    Label("Disable Monitoring", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isNotificationsEnabled)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Access requests log
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent TCC Access Requests")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.accessRequests.isEmpty {
                    Text("No requests yet...")
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
        .navigationTitle("Request Monitoring")
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
                    Text("Request Details")
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
        ReqMonView()
    }
}
