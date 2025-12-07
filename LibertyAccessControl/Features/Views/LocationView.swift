//
//  LocationView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct LocationView: View {
    @StateObject private var viewModel = LocationViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.isLocationEnabled ? "location.fill" : "location.slash")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isLocationEnabled ? .blue : .gray)
            
            Text("Location Services")
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
            
            // Current location display
            VStack(spacing: 8) {
                Text("Current Location")
                    .font(.headline)
                
                Text(viewModel.currentLocation)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(nsColor: .systemGray).opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.vertical)
            
            // Request Location Button
            HStack {
                Button(action: {
                    viewModel.requestLocation()
                }) {
                    Label("Request Location", systemImage: "location.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Enable/Disable continuous updates
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.enableLocation()
                }) {
                    Label("Enable Location", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.isLocationEnabled)
                
                Button(action: {
                    viewModel.disableLocation()
                }) {
                    Label("Disable Location", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isLocationEnabled)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Location Services")
    }
}

#Preview {
    NavigationStack {
        LocationView()
    }
}
