//
//  FullDiskAccessView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct FullDiskAccessView: View {
    @StateObject private var viewModel = FullDiskAccessViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Full Disk Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Full Disk Access")
    }
}

#Preview {
    NavigationStack {
        FullDiskAccessView()
    }
}
