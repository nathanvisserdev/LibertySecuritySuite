//
//  MicrophoneView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI
import AVFoundation

struct MicrophoneView: View {
    @StateObject private var viewModel = MicrophoneViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: microphoneIcon)
                    .font(.system(size: 60))
                    .foregroundColor(microphoneColor)
                
                Text("Microphone Access")
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
            
            // Control Buttons
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.requestAccess()
                }) {
                    Label("Request Access", systemImage: "questionmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.allowAccess()
                    }) {
                        Label("Allow Access", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button(action: {
                        viewModel.denyAccess()
                    }) {
                        Label("Deny Access", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Applications List
            VStack(alignment: .leading, spacing: 8) {
                Text("Application Permissions")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.applications) { app in
                            HStack {
                                Image(systemName: "app.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(app.bundleId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { app.hasAccess },
                                    set: { _ in viewModel.toggleAppAccess(for: app) }
                                ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                            }
                            .padding(12)
                            .background(Color(nsColor: .systemGray).opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("Microphone")
    }
    
    private var microphoneIcon: String {
        switch viewModel.authorizationStatus {
        case .authorized:
            return "mic.fill"
        case .denied, .restricted:
            return "mic.slash.fill"
        case .notDetermined:
            return "mic"
        @unknown default:
            return "mic"
        }
    }
    
    private var microphoneColor: Color {
        switch viewModel.authorizationStatus {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        MicrophoneView()
    }
}
