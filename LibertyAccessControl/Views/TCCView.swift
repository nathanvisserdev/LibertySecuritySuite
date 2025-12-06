//
//  TCCView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct TCCView: View {
    @StateObject private var viewModel = TCCViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("TCC Database")
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
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Load Button
            Button(action: {
                viewModel.loadTCCData()
            }) {
                Label(viewModel.isLoading ? "Loading..." : "Load TCC Permissions", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            .padding(.horizontal)
            
            Divider()
            
            // Entries List
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "app.fill")
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.client)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        Text(entry.serviceName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(entry.statusText)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorForStatus(entry.statusColor))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(colorForStatus(entry.statusColor).opacity(0.2))
                                        .cornerRadius(6)
                                }
                                
                                if let lastModified = entry.lastModified {
                                    Text("Modified: \(lastModified.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("TCC")
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        TCCView()
    }
}
