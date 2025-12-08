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
                                .padding(10)
                                .background(Color(nsColor: .systemGray).opacity(0.2))
                                .cornerRadius(8)
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

#Preview {
    NavigationStack {
        ReqMonView()
    }
}
