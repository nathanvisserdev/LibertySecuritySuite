//
//  REGView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct REGView: View {
    @StateObject private var viewModel = REGViewModel()
    @State private var expandedEntries: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("System TCC Registry")
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
                        .textSelection(.enabled)
                }
            }
            
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
                                // Header - Always visible, clickable
                                Button(action: {
                                    if expandedEntries.contains(entry.id) {
                                        expandedEntries.remove(entry.id)
                                    } else {
                                        expandedEntries.insert(entry.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: expandedEntries.contains(entry.id) ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        
                                        Image(systemName: entry.isTrusted ? "checkmark.shield.fill" : "xmark.shield.fill")
                                            .foregroundColor(entry.isTrusted ? .green : .red)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.abs_path)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            Text("Last seen: \(entry.last_seen.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Show trusted badge
                                        Text(entry.isTrusted ? "Trusted" : "Untrusted")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(entry.isTrusted ? Color.green : Color.red)
                                            .cornerRadius(6)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Expanded details
                                if expandedEntries.contains(entry.id) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        fieldRow("abs_path", value: entry.abs_path)
                                        fieldRow("first_seen", value: entry.first_seen.formatted(date: .abbreviated, time: .shortened))
                                        fieldRow("last_seen", value: entry.last_seen.formatted(date: .abbreviated, time: .shortened))
                                        fieldRow("trusted", value: "\(entry.trusted)")
                                    }
                                    .padding(.top, 4)
                                    .padding(.leading, 24)
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
        .navigationTitle("TCC Registry")
        .onAppear {
            viewModel.loadREGData()
        }
    }
    
    private func fieldRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)
            
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

#Preview {
    REGView()
}
