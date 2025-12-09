//
//  MonitoringPreferencesView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI

struct MonitoringPreferencesView: View {
    @StateObject private var preferences = MonitoringPreferences.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monitoring Preferences")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Configure which services and applications trigger notifications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Notification Filters
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notification Filters")
                        .font(.headline)
                    
                    Toggle("Only notify for denied requests", isOn: $preferences.notifyOnlyDenied)
                        .onChange(of: preferences.notifyOnlyDenied) { _ in
                            preferences.savePreferences()
                        }
                    
                    Toggle("Only notify for high-priority services", isOn: $preferences.notifyHighPriorityOnly)
                        .onChange(of: preferences.notifyHighPriorityOnly) { _ in
                            preferences.savePreferences()
                        }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Monitored Services
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monitored Services")
                        .font(.headline)
                    
                    Text("Select which TCC services you want to monitor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(TCCServiceType.allCases) { service in
                            ServiceToggleRow(
                                service: service,
                                isSelected: preferences.monitoredServices.contains(service)
                            ) { isSelected in
                                if isSelected {
                                    preferences.monitoredServices.insert(service)
                                } else {
                                    preferences.monitoredServices.remove(service)
                                }
                                preferences.savePreferences()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Trusted Apps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trusted Applications")
                        .font(.headline)
                    
                    Text("Apps on this list will not trigger notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if preferences.trustedApps.isEmpty {
                        Text("No trusted apps yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(Array(preferences.trustedApps.sorted()), id: \.self) { bundleId in
                            TrustedAppRow(bundleId: bundleId) {
                                preferences.removeTrustedApp(bundleId)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Monitoring Preferences")
    }
}

struct ServiceToggleRow: View {
    let service: TCCServiceType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if service.isHighPriority {
                        Text("High Priority")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TrustedAppRow: View {
    let bundleId: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(getAppName())
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(bundleId)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(nsColor: .systemGray).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func getAppName() -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return bundleId.components(separatedBy: ".").last ?? bundleId
    }
}

#Preview {
    NavigationStack {
        MonitoringPreferencesView()
    }
}
