import SwiftUI

struct FileSystemMonitorView: View {
    @StateObject private var viewModel = FileSystemViewModel()
    @State private var selectedTab = 0
    @State private var showingFilterSheet = false
    @State private var showingPathSheet = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                headerView
                
                Divider()
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Events").tag(0)
                    Text("Alerts").tag(1)
                    Text("Statistics").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    eventsView
                        .tag(0)
                    
                    alertsView
                        .tag(1)
                    
                    statisticsView
                        .tag(2)
                }
            }
            .navigationTitle("File System Monitor")
            
            // Detail/Info View
            infoDetailView
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Filter button
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    
                    // Paths button
                    Button(action: { showingPathSheet = true }) {
                        Image(systemName: "folder.badge.gearshape")
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
            .sheet(isPresented: $showingPathSheet) {
                pathConfigurationSheet
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
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
                title: "Events/sec",
                value: String(format: "%.1f", viewModel.stats.eventsPerSecond),
                color: .blue,
                icon: "waveform"
            )
            
            StatBox(
                title: "Total Events",
                value: "\(viewModel.stats.totalEvents)",
                color: .purple,
                icon: "chart.bar.fill"
            )
            
            StatBox(
                title: "Threats",
                value: "\(viewModel.stats.suspiciousActivities)",
                color: viewModel.stats.suspiciousActivities > 0 ? .red : .green,
                icon: "exclamationmark.shield.fill"
            )
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Events View
    private var eventsView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search events...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            // Events list
            if viewModel.filteredEvents.isEmpty {
                emptyStateView
            } else {
                List(viewModel.filteredEvents) { event in
                    EventRow(event: event)
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
                    Text("No Security Alerts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("System is operating normally")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.alerts) { alert in
                        AlertRow(alert: alert) {
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
                        StatRow(title: "Total Events", value: "\(viewModel.stats.totalEvents)")
                        StatRow(title: "Monitored Paths", value: "\(viewModel.stats.monitoredPaths)")
                        StatRow(title: "Uptime", value: viewModel.formattedUptime())
                        StatRow(title: "Events/Second", value: String(format: "%.2f", viewModel.stats.eventsPerSecond))
                    }
                }
                
                // Events by Type
                GroupBox(label: Label("Events by Type", systemImage: "list.bullet")) {
                    VStack(spacing: 8) {
                        ForEach(FSEventType.allCases, id: \.self) { type in
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
                
                // Events by Severity
                GroupBox(label: Label("Events by Severity", systemImage: "exclamationmark.triangle")) {
                    VStack(spacing: 8) {
                        ForEach(FileSystemThreatSeverity.allCases, id: \.self) { severity in
                            let count = viewModel.stats.eventsBySeverity[severity] ?? 0
                            if count > 0 {
                                HStack {
                                    Image(systemName: severity.icon)
                                        .foregroundColor(Color(severity.color))
                                    Text(severity.rawValue)
                                    Spacer()
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                
                // Quick Stats
                GroupBox(label: Label("Quick Stats", systemImage: "speedometer")) {
                    VStack(spacing: 8) {
                        StatRow(title: "Events (Last Minute)", value: "\(viewModel.eventsInLastMinute)")
                        StatRow(title: "Critical Events", value: "\(viewModel.criticalEventsCount)")
                        StatRow(title: "High Severity Events", value: "\(viewModel.highSeverityEventsCount)")
                        StatRow(title: "Suspicious Activities", value: "\(viewModel.stats.suspiciousActivities)")
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Info Detail View
    private var infoDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("File System Monitor")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Real-time security & ransomware detection")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Features Section
                GroupBox(label: Label("Features", systemImage: "star.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            icon: "clock.arrow.circlepath",
                            title: "Real-time File System Monitoring",
                            description: "Monitors file modifications in real-time using FSEvents API (create, modify, delete, rename, etc.)"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "exclamationmark.shield.fill",
                            title: "Ransomware Detection",
                            description: "Detects rapid encryption patterns (50+ files in 10s), suspicious extensions (.encrypted, .locked, .crypto), and mass operations"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "lock.shield.fill",
                            title: "System File Integrity",
                            description: "Monitors protected paths (/System, /Library, /usr) with critical alerts for unauthorized modifications"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Threat Classification",
                            description: "Four severity levels (Low, Medium, High, Critical) with intelligent pattern analysis"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "folder.badge.gearshape",
                            title: "Configurable Paths",
                            description: "Monitor specific directories including Home, Documents, Desktop, Downloads, or custom paths"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "arrow.down.doc.fill",
                            title: "CSV Export",
                            description: "Export events for forensic analysis and compliance reporting"
                        )
                    }
                    .padding()
                }
                
                // Technical Details
                GroupBox(label: Label("Technical Details", systemImage: "gearshape.2.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FSDetailRow(label: "API", value: "macOS FSEvents")
                        FSDetailRow(label: "Latency", value: "300ms (real-time)")
                        FSDetailRow(label: "Event Capacity", value: "1000 in-memory")
                        FSDetailRow(label: "Ransomware Threshold", value: "50 files / 10s")
                        FSDetailRow(label: "Architecture", value: "Combine + MVVM")
                    }
                    .padding()
                }
                
                // How to Use
                GroupBox(label: Label("How to Use", systemImage: "questionmark.circle.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HowToStep(number: 1, text: "Click the green play button to start monitoring")
                        HowToStep(number: 2, text: "View real-time events in the Events tab")
                        HowToStep(number: 3, text: "Check critical alerts in the Alerts tab")
                        HowToStep(number: 4, text: "Configure monitored paths using the folder icon")
                        HowToStep(number: 5, text: "Filter events by type, severity, or search")
                        HowToStep(number: 6, text: "Export data to CSV for analysis")
                    }
                    .padding()
                }
                
                // Protected Paths
                GroupBox(label: Label("Protected System Paths", systemImage: "lock.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("/System - macOS system files")
                        Text("/Library - System libraries")
                        Text("/usr - Unix system resources")
                        Text("/bin - Essential binaries")
                        Text("/sbin - System binaries")
                        Text("/private/etc - Configuration files")
                    }
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                Spacer()
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
            
            Text(viewModel.isMonitoring ? "Waiting for events..." : "Monitoring Stopped")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.isMonitoring ? "File system events will appear here" : "Start monitoring to see file system events")
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
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Types")) {
                    ForEach(FSEventType.allCases, id: \.self) { type in
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
                
                Section(header: Text("Severity Levels")) {
                    ForEach(FileSystemThreatSeverity.allCases, id: \.self) { severity in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedSeverities.contains(severity) },
                            set: { _ in viewModel.toggleSeverity(severity) }
                        )) {
                            HStack {
                                Image(systemName: severity.icon)
                                    .foregroundColor(Color(severity.color))
                                Text(severity.rawValue)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Show Only Alerts", isOn: $viewModel.showOnlyAlerts)
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
    
    // MARK: - Path Configuration Sheet
    private var pathConfigurationSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Monitored Paths")) {
                    ForEach(viewModel.monitoredPaths, id: \.self) { path in
                        HStack {
                            Text(path)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button(action: { viewModel.removePath(path) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Add Custom Path")) {
                    HStack {
                        TextField("Path", text: $viewModel.customPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add") {
                            viewModel.addCustomPath()
                        }
                        .disabled(viewModel.customPath.isEmpty)
                    }
                }
                
                Section {
                    Button("Load Default Paths") {
                        viewModel.loadDefaultPaths()
                    }
                }
            }
            .navigationTitle("Monitored Paths")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingPathSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Export Sheet
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Events")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Export \(viewModel.filteredEvents.count) events to CSV")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    let csv = viewModel.exportEvents()
                    // Save CSV
                    let filename = "filesystem_events_\(Date().timeIntervalSince1970).csv"
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
struct EventRow: View {
    let event: FileSystemEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.eventType.icon)
                .font(.title3)
                .foregroundColor(Color(event.eventType.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                // File name
                Text(event.fileName)
                    .font(.headline)
                
                // Path
                Text(event.directory)
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
                // Severity badge
                HStack(spacing: 4) {
                    Image(systemName: event.severity.icon)
                    Text(event.severity.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(event.severity.color).opacity(0.2))
                .foregroundColor(Color(event.severity.color))
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

struct AlertRow: View {
    let alert: FileSystemAlert
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.icon)
                .font(.title2)
                .foregroundColor(Color(alert.severity.color))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(Color(alert.severity.color))
                
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
        .background(Color(alert.severity.color).opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FSDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct HowToStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct FileSystemMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        FileSystemMonitorView()
    }
}
