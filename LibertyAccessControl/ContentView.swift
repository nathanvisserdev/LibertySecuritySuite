//
//  ContentView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    HomeView()
                } label: {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationLink {
                    DashboardView()
                } label: {
                    Label("TCC Database Viewer", systemImage: "list.bullet.rectangle")
                }
                
                NavigationLink {
                    RequestPermissionsView()
                } label: {
                    Label("Permission Management", systemImage: "lock.shield.fill")
                }
                
                NavigationLink {
                    SecurityMonitorView()
                } label: {
                    Label("Security Monitor", systemImage: "shield.checkered")
                }
                
                NavigationLink {
                    BlacklistManagementView()
                } label: {
                    Label("Blacklist Management", systemImage: "hand.raised.fill")
                }
                
                NavigationLink {
                    MonitoringPreferencesView()
                } label: {
                    Label("Monitoring Preferences", systemImage: "slider.horizontal.3")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
}
