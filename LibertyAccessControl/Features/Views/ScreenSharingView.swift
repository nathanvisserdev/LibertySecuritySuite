//
//  ScreenSharingView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct ScreenSharingView: View {
    @StateObject private var viewModel = ScreenSharingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.isSharingEnabled ? "rectangle.on.rectangle" : "rectangle.slash")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isSharingEnabled ? .blue : .gray)
            
            Text("Screen Sharing")
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
                    viewModel.enableSharing()
                }) {
                    Label("Enable Sharing", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.isSharingEnabled)
                
                Button(action: {
                    viewModel.disableSharing()
                }) {
                    Label("Disable Sharing", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isSharingEnabled)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Screen Sharing")
    }
}

#Preview {
    NavigationStack {
        ScreenSharingView()
    }
}
