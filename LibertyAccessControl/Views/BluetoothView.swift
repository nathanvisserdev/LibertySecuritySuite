//
//  BluetoothView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct BluetoothView: View {
    @StateObject private var viewModel = BluetoothViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Bluetooth")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Bluetooth")
    }
}

#Preview {
    NavigationStack {
        BluetoothView()
    }
}
