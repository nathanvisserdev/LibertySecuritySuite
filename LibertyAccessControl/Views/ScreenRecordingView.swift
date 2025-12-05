//
//  ScreenRecordingView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct ScreenRecordingView: View {
    @StateObject private var viewModel = ScreenRecordingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Screen Recording")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Screen Recording")
    }
}

#Preview {
    NavigationStack {
        ScreenRecordingView()
    }
}
