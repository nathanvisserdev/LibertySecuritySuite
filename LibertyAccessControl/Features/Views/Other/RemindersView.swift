//
//  RemindersView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI
import EventKit

struct RemindersView: View {
    @StateObject private var viewModel = RemindersViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: remindersIcon)
                    .font(.system(size: 60))
                    .foregroundColor(remindersColor)
                
                Text("Reminders Access")
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
            Button(action: {
                viewModel.requestAccess()
            }) {
                Label("Request Access", systemImage: "questionmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
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
                                .labelsHidden()
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
        .navigationTitle("Reminders")
    }
    
    private var remindersIcon: String {
        switch viewModel.authorizationStatus {
        case .fullAccess, .authorized:
            return "checklist.checked"
        case .denied, .restricted:
            return "checklist.unchecked"
        default:
            return "checklist"
        }
    }
    
    private var remindersColor: Color {
        switch viewModel.authorizationStatus {
        case .fullAccess, .authorized:
            return .green
        case .denied, .restricted:
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        RemindersView()
    }
}

