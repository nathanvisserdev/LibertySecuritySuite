//
//  CameraView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Camera")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Camera")
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
