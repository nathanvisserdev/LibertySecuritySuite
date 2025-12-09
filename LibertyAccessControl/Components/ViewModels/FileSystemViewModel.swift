import Foundation
import Combine

class FileSystemViewModel: ObservableObject {
    @Published var events: [FileSystemEvent] = []
    @Published var filteredEvents: [FileSystemEvent] = []
    @Published var alerts: [FileSystemAlert] = []
    @Published var stats: FileSystemStats
    @Published var isMonitoring: Bool = false
    
    // Filters
    @Published var selectedEventTypes: Set<FSEventType> = Set(FSEventType.allCases)
    @Published var selectedSeverities: Set<FileSystemThreatSeverity> = []
    @Published var searchText: String = ""
    @Published var showOnlyAlerts: Bool = false
    
    // Configuration
    @Published var monitoredPaths: [String] = []
    @Published var customPath: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let monitorService = FileSystemMonitorService.shared
    
    init() {
        self.stats = FileSystemStats()
        self.selectedSeverities = Set(FileSystemThreatSeverity.allCases)
        setupBindings()
        loadDefaultPaths()
    }
    
    private func setupBindings() {
        // Bind to monitor service
        monitorService.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.events = events
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        monitorService.$alerts
            .receive(on: DispatchQueue.main)
            .assign(to: &$alerts)
        
        monitorService.$stats
            .receive(on: DispatchQueue.main)
            .assign(to: &$stats)
        
        monitorService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)
        
        // Apply filters when filter settings change
        Publishers.CombineLatest4($selectedEventTypes, $selectedSeverities, $searchText, $showOnlyAlerts)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Monitoring Control
    func startMonitoring() {
        if monitoredPaths.isEmpty {
            loadDefaultPaths()
        }
        monitorService.startMonitoring(paths: monitoredPaths)
    }
    
    func stopMonitoring() {
        monitorService.stopMonitoring()
    }
    
    func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }
    
    // MARK: - Path Management
    func loadDefaultPaths() {
        var paths: [String] = []
        
        if let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? {
            paths.append(homeDir)
        }
        
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            paths.append(docsDir)
        }
        
        if let desktopDir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path {
            paths.append(desktopDir)
        }
        
        if let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path {
            paths.append(downloadsDir)
        }
        
        monitoredPaths = Array(Set(paths)) // Remove duplicates
    }
    
    func addCustomPath() {
        guard !customPath.isEmpty else { return }
        
        let path = customPath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate path exists
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            if !monitoredPaths.contains(path) {
                monitoredPaths.append(path)
                customPath = ""
                
                // Restart monitoring if already running
                if isMonitoring {
                    stopMonitoring()
                    startMonitoring()
                }
            }
        }
    }
    
    func removePath(_ path: String) {
        monitoredPaths.removeAll { $0 == path }
        
        // Restart monitoring if already running
        if isMonitoring {
            stopMonitoring()
            if !monitoredPaths.isEmpty {
                startMonitoring()
            }
        }
    }
    
    // MARK: - Filtering
    func applyFilters() {
        var filtered = events
        
        // Filter by event type
        if !selectedEventTypes.isEmpty && selectedEventTypes.count < FSEventType.allCases.count {
            filtered = filtered.filter { selectedEventTypes.contains($0.eventType) }
        }
        
        // Filter by severity
        if !selectedSeverities.isEmpty && selectedSeverities.count < ThreatSeverity.allCases.count {
            filtered = filtered.filter { selectedSeverities.contains($0.severity) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            filtered = filtered.filter {
                $0.path.lowercased().contains(search) ||
                $0.details.lowercased().contains(search) ||
                $0.fileName.lowercased().contains(search)
            }
        }
        
        // Show only events with alerts
        if showOnlyAlerts {
            filtered = filtered.filter { $0.severity == .high || $0.severity == .critical }
        }
        
        filteredEvents = filtered
    }
    
    func resetFilters() {
        selectedEventTypes = Set(FSEventType.allCases)
        selectedSeverities = Set(FileSystemThreatSeverity.allCases)
        searchText = ""
        showOnlyAlerts = false
    }
    
    func toggleEventType(_ type: FSEventType) {
        if selectedEventTypes.contains(type) {
            selectedEventTypes.remove(type)
        } else {
            selectedEventTypes.insert(type)
        }
    }
    
    func toggleSeverity(_ severity: FileSystemThreatSeverity) {
        if selectedSeverities.contains(severity) {
            selectedSeverities.remove(severity)
        } else {
            selectedSeverities.insert(severity)
        }
    }
    
    // MARK: - Actions
    func clearEvents() {
        monitorService.clearEvents()
        filteredEvents.removeAll()
    }
    
    func clearAlerts() {
        monitorService.clearAlerts()
    }
    
    func exportEvents() -> String {
        var csv = "Timestamp,Path,Event Type,Severity,Details\n"
        
        for event in filteredEvents {
            let row = "\"\(event.formattedTimestamp)\",\"\(event.path)\",\"\(event.eventType.rawValue)\",\"\(event.severity.rawValue)\",\"\(event.details)\"\n"
            csv += row
        }
        
        return csv
    }
    
    func dismissAlert(_ alert: FileSystemAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    // MARK: - Statistics
    var eventsInLastMinute: Int {
        let now = Date()
        return events.filter { now.timeIntervalSince($0.timestamp) < 60 }.count
    }
    
    var criticalEventsCount: Int {
        events.filter { $0.severity == .critical }.count
    }
    
    var highSeverityEventsCount: Int {
        events.filter { $0.severity == .high }.count
    }
    
    var recentAlerts: [FileSystemAlert] {
        Array(alerts.prefix(5))
    }
    
    // MARK: - Helpers
    func formattedUptime() -> String {
        let hours = Int(stats.uptime) / 3600
        let minutes = (Int(stats.uptime) % 3600) / 60
        let seconds = Int(stats.uptime) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
