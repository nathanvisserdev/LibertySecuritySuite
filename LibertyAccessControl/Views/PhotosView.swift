//
//  PhotosView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct PhotosView: View {
    @StateObject private var viewModel = PhotosViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Photos")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Photos")
    }
}

#Preview {
    NavigationStack {
        PhotosView()
    }
}
