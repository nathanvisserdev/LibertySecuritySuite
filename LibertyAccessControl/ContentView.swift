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
                    NetworkMonitorView()
                } label: {
                    Label("Network & Firewall", systemImage: "network")
                }
                
                NavigationLink {
                    FileSystemMonitorView()
                } label: {
                    Label("File System Monitor", systemImage: "doc.text.magnifyingglass")
                }
                
                NavigationLink {
                    ProcessMonitorView()
                } label: {
                    Label("Process Monitor", systemImage: "arrow.triangle.2.circlepath")
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
                
                Divider()
                
                NavigationLink {
                    MalwareAnalysisView()
                } label: {
                    Label("Malware Detection", systemImage: "ant.fill")
                }
                
                NavigationLink {
                    SecureNotesView()
                } label: {
                    Label("Secure Notes", systemImage: "lock.doc")
                }
                
                NavigationLink {
                    FileEncryptionView()
                } label: {
                    Label("File Encryption", systemImage: "lock.shield.fill")
                }

                NavigationLink {
                    FileEncryptGPGView()
                } label: {
                    Label("File Encrypt (GPG)", systemImage: "lock.shield")
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
