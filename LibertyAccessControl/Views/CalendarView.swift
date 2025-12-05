//
//  CalendarView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Calendar")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Calendar")
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
