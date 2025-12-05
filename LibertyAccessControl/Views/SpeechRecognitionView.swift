//
//  SpeechRecognitionView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct SpeechRecognitionView: View {
    @StateObject private var viewModel = SpeechRecognitionViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Speech Recognition")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Speech Recognition")
    }
}

#Preview {
    NavigationStack {
        SpeechRecognitionView()
    }
}
