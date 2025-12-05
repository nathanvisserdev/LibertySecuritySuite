//
//  AccessibilityView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct AccessibilityView: View {
    @StateObject private var viewModel = AccessibilityViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "accessibility.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Accessibility")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Accessibility")
    }
}

#Preview {
    NavigationStack {
        AccessibilityView()
    }
}
