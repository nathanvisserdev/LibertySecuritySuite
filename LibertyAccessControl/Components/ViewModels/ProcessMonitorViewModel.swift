import Foundation
import Combine

class ProcessMonitorViewModel: ObservableObject {
    @Published var events: [ProcessEvent] = []
    @Published var filteredEvents: [ProcessEvent] = []
    @Published var alerts: [ProcessAlert] = []
    @Published var stats: ProcessStats
    @Published var isMonitoring: Bool = false
    @Published var helperInstallationStatus: HelperInstallationStatus = .notInstalled
    
    // Helper manager - stored separately, bridged through published properties
    let helperManager: PrivilegedHelperManager
    
    // Filters
    @Published var selectedEventTypes: Set<ProcessEventType> = Set(ProcessEventType.allCases)
    @Published var selectedThreatLevels: Set<ProcessThreatLevel> = Set(ProcessThreatLevel.allCases)
    @Published var selectedSignatureStatus: Set<CodeSignatureStatus> = Set(CodeSignatureStatus.allCases)
    @Published var searchText: String = ""
    @Published var showOnlyThreats: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let monitorService = ProcessMonitorService.shared
    
    init() {
        self.stats = ProcessStats()
        self.helperManager = PrivilegedHelperManager()
        setupBindings()
        
        // Connect helper manager to monitor service
        monitorService.setHelperManager(helperManager)
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
        
        // Bridge helper manager status to published property
        helperManager.$installationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$helperInstallationStatus)
        
        monitorService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)
        
        // Apply filters when settings change
        Publishers.CombineLatest4($selectedEventTypes, $selectedThreatLevels, $selectedSignatureStatus, $searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $showOnlyThreats
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        monitorService.startMonitoring()
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
    
    // MARK: - Filtering
    
    func applyFilters() {
        var filtered = events
        
        // Filter by event type
        if !selectedEventTypes.isEmpty && selectedEventTypes.count < ProcessEventType.allCases.count {
            filtered = filtered.filter { selectedEventTypes.contains($0.eventType) }
        }
        
        // Filter by threat level
        if !selectedThreatLevels.isEmpty && selectedThreatLevels.count < ProcessThreatLevel.allCases.count {
            filtered = filtered.filter { selectedThreatLevels.contains($0.threatLevel) }
        }
        
        // Filter by signature status
        if !selectedSignatureStatus.isEmpty && selectedSignatureStatus.count < CodeSignatureStatus.allCases.count {
            filtered = filtered.filter { selectedSignatureStatus.contains($0.codeSignatureStatus) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            filtered = filtered.filter {
                $0.processName.lowercased().contains(search) ||
                $0.executablePath.lowercased().contains(search) ||
                $0.details.lowercased().contains(search) ||
                $0.user.lowercased().contains(search)
            }
        }
        
        // Show only threats
        if showOnlyThreats {
            filtered = filtered.filter {
                $0.threatLevel == .suspicious ||
                $0.threatLevel == .malicious ||
                $0.threatLevel == .critical
            }
        }
        
        filteredEvents = filtered
    }
    
    func resetFilters() {
        selectedEventTypes = Set(ProcessEventType.allCases)
        selectedThreatLevels = Set(ProcessThreatLevel.allCases)
        selectedSignatureStatus = Set(CodeSignatureStatus.allCases)
        searchText = ""
        showOnlyThreats = false
    }
    
    func toggleEventType(_ type: ProcessEventType) {
        if selectedEventTypes.contains(type) {
            selectedEventTypes.remove(type)
        } else {
            selectedEventTypes.insert(type)
        }
    }
    
    func toggleThreatLevel(_ level: ProcessThreatLevel) {
        if selectedThreatLevels.contains(level) {
            selectedThreatLevels.remove(level)
        } else {
            selectedThreatLevels.insert(level)
        }
    }
    
    func toggleSignatureStatus(_ status: CodeSignatureStatus) {
        if selectedSignatureStatus.contains(status) {
            selectedSignatureStatus.remove(status)
        } else {
            selectedSignatureStatus.insert(status)
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
        var csv = "Timestamp,PID,Process Name,Path,Parent,Event Type,Threat Level,Signature,User,Details\n"
        
        for event in filteredEvents {
            let row = "\"\(event.formattedTimestamp)\",\(event.processID),\"\(event.processName)\",\"\(event.executablePath)\",\"\(event.parentProcessName)\",\"\(event.eventType.rawValue)\",\"\(event.threatLevel.rawValue)\",\"\(event.codeSignatureStatus.rawValue)\",\"\(event.user)\",\"\(event.details)\"\n"
            csv += row
        }
        
        return csv
    }
    
    func dismissAlert(_ alert: ProcessAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func killProcess(pid: pid_t) {
        kill(pid, SIGTERM)
    }
    
    // MARK: - Statistics
    
    var threatsCount: Int {
        events.filter {
            $0.threatLevel == .suspicious ||
            $0.threatLevel == .malicious ||
            $0.threatLevel == .critical
        }.count
    }
    
    var unsignedProcesses: Int {
        events.filter { $0.codeSignatureStatus == .notSigned || $0.codeSignatureStatus == .invalid }.count
    }
    
    var recentEvents: [ProcessEvent] {
        let now = Date()
        return events.filter { now.timeIntervalSince($0.timestamp) < 60 }
    }
    
    var recentAlerts: [ProcessAlert] {
        Array(alerts.prefix(5))
    }
}
