//
//  TCCView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct TCCView: View {
    @StateObject private var viewModel = TCCViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TCC")
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .navigationTitle("TCC")
    }
}

#Preview {
    NavigationStack {
        TCCView()
    }
}
