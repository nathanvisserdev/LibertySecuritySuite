//
//  RemindersView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct RemindersView: View {
    @StateObject private var viewModel = RemindersViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Reminders")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Reminders")
    }
}

#Preview {
    NavigationStack {
        RemindersView()
    }
}
