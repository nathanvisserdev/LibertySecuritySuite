//
//  RemoteManagementView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct RemoteManagementView: View {
    @StateObject private var viewModel = RemoteManagementViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.isManagementEnabled ? "desktopcomputer" : "desktopcomputer.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isManagementEnabled ? .green : .gray)
            
            Text("Remote Management")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.enableManagement()
                }) {
                    Label("Enable Management", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewModel.isManagementEnabled)
                
                Button(action: {
                    viewModel.disableManagement()
                }) {
                    Label("Disable Management", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isManagementEnabled)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Remote Management")
    }
}

#Preview {
    NavigationStack {
        RemoteManagementView()
    }
}
