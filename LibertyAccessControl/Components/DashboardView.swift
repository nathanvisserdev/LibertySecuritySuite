//
//  DashboardView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import SwiftUI

struct DashboardView: View {
    @State private var selectedView: DashboardTab = .permissions
    
    enum DashboardTab {
        case permissions
        case user
        case system
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Area with embedded toolbar
            Group {
                switch selectedView {
                case .permissions:
                    PermissionsView()
                case .user:
                    UserView()
                case .system:
                    SystemView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Button("All") {
                        selectedView = .permissions
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .permissions ? .blue : .primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("User") {
                        selectedView = .user
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .user ? .blue : .primary)
                    
                    Text("|")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Button("System") {
                        selectedView = .system
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                    .foregroundColor(selectedView == .system ? .blue : .primary)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
