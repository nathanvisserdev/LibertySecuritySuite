//
//  AppleEventsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct AppleEventsView: View {
    @StateObject private var viewModel = AppleEventsViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "applescript.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Apple Events")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Apple Events")
    }
}

#Preview {
    NavigationStack {
        AppleEventsView()
    }
}
