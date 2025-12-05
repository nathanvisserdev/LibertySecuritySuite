//
//  TSSView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct TSSView: View {
    @StateObject private var viewModel = TSSViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: viewModel.isTSSEnabled ? "checkmark.seal.fill" : "checkmark.seal")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.isTSSEnabled ? .blue : .gray)
                
                Text("TCC Daemon Monitor")
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
                    viewModel.enableTSS()
                }) {
                    Label("Enable Monitoring", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.isTSSEnabled)
                
                Button(action: {
                    viewModel.disableTSS()
                }) {
                    Label("Disable Monitoring", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isTSSEnabled)
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
        .navigationTitle("TCC Monitor")
    }
}

#Preview {
    NavigationStack {
        TSSView()
    }
}
