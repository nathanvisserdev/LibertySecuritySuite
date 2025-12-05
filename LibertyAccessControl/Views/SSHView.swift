//
//  SSHView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct SSHView: View {
    @StateObject private var viewModel = SSHViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.isSSHEnabled ? "terminal.fill" : "terminal")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isSSHEnabled ? .green : .gray)
            
            Text("SSH Access")
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
                    viewModel.enableSSH()
                }) {
                    Label("Enable SSH", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewModel.isSSHEnabled)
                
                Button(action: {
                    viewModel.disableSSH()
                }) {
                    Label("Disable SSH", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isSSHEnabled)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("SSH Access")
    }
}

#Preview {
    NavigationStack {
        SSHView()
    }
}
