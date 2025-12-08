//
//  RequestListView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct RequestListView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Request List")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("View and manage permission requests")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Request List")
    }
}

#Preview {
    RequestListView()
}
