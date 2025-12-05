//
//  AllowRemoteFileAccessView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct AllowRemoteFileAccessView: View {
    @StateObject private var viewModel = AllowRemoteFileAccessViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.isAccessGranted ? "checkmark.shield.fill" : "shield.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isAccessGranted ? .green : .red)
            
            Text("Remote File Access")
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
                    viewModel.grantAccess()
                }) {
                    Label("Grant Access", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewModel.isAccessGranted)
                
                Button(action: {
                    viewModel.revokeAccess()
                }) {
                    Label("Revoke Access", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isAccessGranted)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Remote File Access")
    }
}

#Preview {
    NavigationStack {
        AllowRemoteFileAccessView()
    }
}
