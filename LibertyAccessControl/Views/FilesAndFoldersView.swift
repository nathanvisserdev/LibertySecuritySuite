//
//  FilesAndFoldersView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct FilesAndFoldersView: View {
    @StateObject private var viewModel = FilesAndFoldersViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Files and Folders")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Files and Folders")
    }
}

#Preview {
    NavigationStack {
        FilesAndFoldersView()
    }
}
