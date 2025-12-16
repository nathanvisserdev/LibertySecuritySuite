import SwiftUI

struct ProcessMonitorView: View {
    @StateObject private var viewModel = ProcessMonitorViewModel()
    @State private var selectedTab = 0
    @State private var showingFilterSheet = false
    @State private var showingExportSheet = false
    @State private var showingHelperInstallation = false
    @State private var selectedProcess: ProcessEvent?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Helper status banner
                if viewModel.helperInstallationStatus != .installed {
                    helperStatusBanner
                }
                
                // Header with stats
                headerView
                
                Divider()
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Processes").tag(0)
                    Text("Alerts").tag(1)
                    Text("Statistics").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    processesView
                        .tag(0)
                    
                    alertsView
                        .tag(1)
                    
                    statisticsView
                        .tag(2)
                }
            }
            .navigationTitle("Process Monitor")
            .sheet(isPresented: $showingHelperInstallation) {
                HelperInstallationView(helperManager: viewModel.helperManager)
            }
            
            // Info panel
            infoDetailView
            
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Helper status button
                    Button(action: { showingHelperInstallation = true }) {
                        Image(systemName: helperStatusIcon)
                            .foregroundColor(helperStatusColor)
                    }
                    
                    // Filter button
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    
                    // Clear button
                    Menu {
                        Button(action: viewModel.clearEvents) {
                            Label("Clear Events", systemImage: "trash")
                        }
                        Button(action: viewModel.clearAlerts) {
                            Label("Clear Alerts", systemImage: "bell.slash")
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    
                    // Export button
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    // Start/Stop button
                    Button(action: viewModel.toggleMonitoring) {
                        Image(systemName: viewModel.isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(viewModel.isMonitoring ? .red : .green)
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterSheet
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }
    
    // MARK: - Helper Status
    
    private var helperStatusBanner: some View {
        HStack {
            Image(systemName: helperStatusIcon)
                .foregroundColor(helperStatusColor)
            
            Text(helperStatusMessage)
                .font(.subheadline)
            
            Spacer()
            
            Button("Setup") {
                showingHelperInstallation = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(helperStatusColor.opacity(0.1))
    }
    
    private var helperStatusIcon: String {
        switch viewModel.helperInstallationStatus {
        case .installed: return "checkmark.circle.fill"
        case .notInstalled: return "exclamationmark.triangle.fill"
        case .needsUpdate: return "arrow.triangle.2.circlepath.circle.fill"
        case .installedButNotRunning: return "pause.circle.fill"
        }
    }
    
    private var helperStatusColor: Color {
        switch viewModel.helperInstallationStatus {
        case .installed: return .green
        case .notInstalled: return .red
        case .needsUpdate: return .orange
        case .installedButNotRunning: return .yellow
        }
    }
    
    private var helperStatusMessage: String {
        switch viewModel.helperInstallationStatus {
        case .installed: return "Helper tool ready"
        case .notInstalled: return "Helper tool not installed - Process monitoring unavailable"
        case .needsUpdate: return "Helper tool update available"
        case .installedButNotRunning: return "Helper tool not responding"
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 20) {
            StatBox(
                title: "Status",
                value: viewModel.isMonitoring ? "Active" : "Stopped",
                color: viewModel.isMonitoring ? .green : .gray,
                icon: viewModel.isMonitoring ? "checkmark.circle.fill" : "pause.circle.fill"
            )
            
            StatBox(
                title: "Total Processes",
                value: "\(viewModel.stats.totalProcesses)",
                color: .blue,
                icon: "arrow.triangle.2.circlepath"
            )
            
            StatBox(
                title: "Running",
                value: "\(viewModel.stats.runningProcesses)",
                color: .purple,
                icon: "play.circle.fill"
            )
            
            StatBox(
                title: "Threats",
                value: "\(viewModel.stats.suspiciousProcesses)",
                color: viewModel.stats.suspiciousProcesses > 0 ? .red : .green,
                icon: "exclamationmark.shield.fill"
            )
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Processes View
    private var processesView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search processes...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Toggle("Threats Only", isOn: $viewModel.showOnlyThreats)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding()
            
            // Process list
            if viewModel.filteredEvents.isEmpty {
                emptyStateView
            } else {
                List(viewModel.filteredEvents) { event in
                    ProcessRow(event: event)
                        .contextMenu {
                            Button("Kill Process") {
                                viewModel.killProcess(pid: event.processID)
                            }
                            Button("Copy Path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(event.executablePath, forType: .string)
                            }
                        }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Alerts View
    private var alertsView: some View {
        VStack {
            if viewModel.alerts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("No Process Threats")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("All processes appear benign")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.alerts) { alert in
                        ProcessAlertRow(alert: alert) {
                            viewModel.dismissAlert(alert)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview
                GroupBox(label: Label("Overview", systemImage: "chart.bar.doc.horizontal")) {
                    VStack(spacing: 12) {
                        StatRow(title: "Total Processes", value: "\(viewModel.stats.totalProcesses)")
                        StatRow(title: "Running Processes", value: "\(viewModel.stats.runningProcesses)")
                        StatRow(title: "Suspicious Processes", value: "\(viewModel.stats.suspiciousProcesses)")
                        StatRow(title: "Injection Attempts", value: "\(viewModel.stats.injectionAttempts)")
                        StatRow(title: "Privilege Escalations", value: "\(viewModel.stats.privilegeEscalations)")
                    }
                }
                
                // Events by Type
                GroupBox(label: Label("Events by Type", systemImage: "list.bullet")) {
                    VStack(spacing: 8) {
                        ForEach(ProcessEventType.allCases, id: \.self) { type in
                            let count = viewModel.stats.eventsByType[type] ?? 0
                            if count > 0 {
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundColor(Color(type.color))
                                    Text(type.rawValue)
                                    Spacer()
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                
                // Threat Levels
                GroupBox(label: Label("Threat Levels", systemImage: "exclamationmark.triangle")) {
                    VStack(spacing: 8) {
                        ForEach(ProcessThreatLevel.allCases, id: \.self) { level in
                            let count = viewModel.stats.eventsByThreat[level] ?? 0
                            if count > 0 {
                                HStack {
                                    Image(systemName: level.icon)
                                        .foregroundColor(Color(level.color))
                                    Text(level.rawValue)
                                    Spacer()
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                
                // Code Signatures
                GroupBox(label: Label("Code Signatures", systemImage: "checkmark.seal")) {
                    VStack(spacing: 8) {
                        ForEach(CodeSignatureStatus.allCases, id: \.self) { status in
                            let count = viewModel.stats.signatureStats[status] ?? 0
                            if count > 0 {
                                HStack {
                                    Image(systemName: status.icon)
                                        .foregroundColor(Color(status.color))
                                    Text(status.rawValue)
                                    Spacer()
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.isMonitoring ? "hourglass" : "play.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(viewModel.isMonitoring ? "Waiting for processes..." : "Monitoring Stopped")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.isMonitoring ? "Process events will appear here" : "Start monitoring to see process executions")
                .foregroundColor(.secondary)
            
            if !viewModel.isMonitoring {
                Button(action: viewModel.startMonitoring) {
                    Label("Start Monitoring", systemImage: "play.fill")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Info Detail View
    private var infoDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Process Monitor")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Real-time process & binary validation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Features
                GroupBox(label: Label("Features", systemImage: "star.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Real-time Process Monitoring",
                            description: "Monitors all process launches using EndpointSecurity framework with kernel-level visibility"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "checkmark.seal.fill",
                            title: "Code Signature Validation",
                            description: "Validates code signatures on execution, detects unsigned, invalid, and revoked certificates"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "syringe",
                            title: "Injection Detection",
                            description: "Detects dylib injection, process hollowing, and memory modification attempts"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "arrow.triangle.branch",
                            title: "Process Tree Tracking",
                            description: "Tracks parent-child relationships to detect suspicious process chains"
                        )
                    }
                    .padding()
                }
                
                // Technical Details
                GroupBox(label: Label("Technical Details", systemImage: "gearshape.2.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FSDetailRow(label: "API", value: "EndpointSecurity")
                        FSDetailRow(label: "Level", value: "Kernel-level")
                        FSDetailRow(label: "Validation", value: "SecStaticCode")
                        FSDetailRow(label: "Event Capacity", value: "1000 in-memory")
                        FSDetailRow(label: "Architecture", value: "Combine + MVVM")
                    }
                    .padding()
                }
                
                // Requirements
                GroupBox(label: Label("Requirements", systemImage: "exclamationmark.triangle.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Endpoint Security entitlement")
                        Text("• TCC approval for system events")
                        Text("• May require SIP disabled for development")
                        Text("• Root/admin privileges recommended")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Types")) {
                    ForEach(ProcessEventType.allCases, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedEventTypes.contains(type) },
                            set: { _ in viewModel.toggleEventType(type) }
                        )) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(Color(type.color))
                                Text(type.rawValue)
                            }
                        }
                    }
                }
                
                Section(header: Text("Threat Levels")) {
                    ForEach(ProcessThreatLevel.allCases, id: \.self) { level in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedThreatLevels.contains(level) },
                            set: { _ in viewModel.toggleThreatLevel(level) }
                        )) {
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(Color(level.color))
                                Text(level.rawValue)
                            }
                        }
                    }
                }
                
                Section(header: Text("Signature Status")) {
                    ForEach(CodeSignatureStatus.allCases, id: \.self) { status in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedSignatureStatus.contains(status) },
                            set: { _ in viewModel.toggleSignatureStatus(status) }
                        )) {
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundColor(Color(status.color))
                                Text(status.rawValue)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Reset Filters") {
                        viewModel.resetFilters()
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Export Sheet
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Process Events")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Export \(viewModel.filteredEvents.count) events to CSV")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    let csv = viewModel.exportEvents()
                    let filename = "process_events_\(Date().timeIntervalSince1970).csv"
                    if let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                        let fileURL = dir.appendingPathComponent(filename)
                        try? csv.write(to: fileURL, atomically: true, encoding: .utf8)
                        print("Exported to: \(fileURL.path)")
                    }
                    showingExportSheet = false
                }) {
                    Label("Export to Downloads", systemImage: "arrow.down.doc")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProcessRow: View {
    let event: ProcessEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.eventType.icon)
                .font(.title3)
                .foregroundColor(Color(event.eventType.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                // Process name
                HStack {
                    Text(event.processName)
                        .font(.headline)
                    Text("(\(event.processID))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Path
                Text(event.executablePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Details
                Text(event.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Signature badge
                HStack(spacing: 4) {
                    Image(systemName: event.codeSignatureStatus.icon)
                    Text(event.codeSignatureStatus.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(event.codeSignatureStatus.color).opacity(0.2))
                .foregroundColor(Color(event.codeSignatureStatus.color))
                .cornerRadius(8)
                
                // Threat badge
                HStack(spacing: 4) {
                    Image(systemName: event.threatLevel.icon)
                    Text(event.threatLevel.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(event.threatLevel.color).opacity(0.2))
                .foregroundColor(Color(event.threatLevel.color))
                .cornerRadius(8)
                
                // Timestamp
                Text(event.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProcessAlertRow: View {
    let alert: ProcessAlert
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.threatLevel.icon)
                .font(.title2)
                .foregroundColor(Color(alert.threatLevel.color))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(Color(alert.threatLevel.color))
                
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(alert.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(alert.threatLevel.color).opacity(0.1))
        .cornerRadius(10)
    }
}

struct ProcessMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessMonitorView()
    }
}
