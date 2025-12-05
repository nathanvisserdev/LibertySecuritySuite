//
//  ContactsView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct ContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Contacts")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Contacts")
    }
}

#Preview {
    NavigationStack {
        ContactsView()
    }
}
