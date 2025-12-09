import Foundation
import Combine

class ProcessMonitorService: ObservableObject {
    static let shared = ProcessMonitorService()
    
    @Published var events: [ProcessEvent] = []
    @Published var stats: ProcessStats = ProcessStats()
    @Published var isMonitoring: Bool = false
    @Published var alerts: [ProcessAlert] = []
    @Published var runningProcesses: [pid_t: MonitoredProcessInfo] = [:]
    
    private var helperManager: PrivilegedHelperManager?
    private var eventQueue = DispatchQueue(label: "com.liberty.processmonitor", qos: .userInitiated)
    private var statsTimer: Timer?
    private let maxStoredEvents = 1000
    
    // Process tree tracking
    private var processTree: [pid_t: ProcessTreeNode] = [:]
    
    // Injection tracking
    private var injectionDetections: [InjectionDetection] = []
    
    private init() {}
    
    // MARK: - Helper Manager Setup
    
    func setHelperManager(_ manager: PrivilegedHelperManager) {
        self.helperManager = manager
        manager.setDelegate(self)
    }
    
    // MARK: - Start/Stop Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        guard let helper = helperManager else {
            print("❌ PrivilegedHelperManager not set")
            return
        }
        
        // Use XPC to start monitoring in privileged helper
        helper.startProcessMonitoring { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.isMonitoring = true
                    self?.startStatsTimer()
                    print("✅ Process monitoring started via privileged helper")
                case .failure(let error):
                    print("❌ Failed to start monitoring: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        guard let helper = helperManager else { return }
        
        helper.stopProcessMonitoring { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.isMonitoring = false
                    self?.statsTimer?.invalidate()
                    self?.statsTimer = nil
                    print("⏹️ Process monitoring stopped via privileged helper")
                case .failure(let error):
                    print("❌ Failed to stop monitoring: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Process Event Handling (called by helper via XPC)
    
    func handleProcessEvent(_ event: ProcessEvent) {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Add to events list
                self.events.insert(event, at: 0)
                
                // Trim old events
                if self.events.count > self.maxStoredEvents {
                    self.events = Array(self.events.prefix(self.maxStoredEvents))
                }
                
                // Update running processes
                if event.eventType == .exec || event.eventType == .fork {
                    let processInfo = MonitoredProcessInfo(
                        processID: event.processID,
                        processName: event.processName,
                        executablePath: event.executablePath,
                        parentProcessID: event.parentProcessID,
                        user: event.user,
                        signatureStatus: event.codeSignatureStatus,
                        threatLevel: event.threatLevel,
                        timestamp: event.timestamp
                    )
                    self.runningProcesses[event.processID] = processInfo
                } else if event.eventType == .exit {
                    self.runningProcesses.removeValue(forKey: event.processID)
                }
                
                // Update stats
                self.stats.totalProcesses += 1
                if event.threatLevel == .malicious || event.threatLevel == .critical {
                    self.stats.suspiciousProcesses += 1
                }
            }
        }
    }
    
    func handleAlert(_ alert: ProcessAlert) {
        DispatchQueue.main.async { [weak self] in
            self?.alerts.insert(alert, at: 0)
            // Stats updated by helper via didUpdateStatistics
        }
    }
    
    // MARK: - Helper Methods
    
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.stats.runningProcesses = self.runningProcesses.count
        }
    }
    
    // MARK: - Utilities
    
    func clearEvents() {
        events.removeAll()
        stats = ProcessStats()
    }
    
    func clearAlerts() {
        alerts.removeAll()
    }
}

// MARK: - PrivilegedHelperDelegateProtocol Implementation

extension ProcessMonitorService: PrivilegedHelperDelegateProtocol {
    
    func didReceiveProcessEvent(
        timestamp: Date,
        processID: Int32,
        processName: String,
        executablePath: String,
        parentProcessID: Int32,
        parentProcessName: String,
        eventTypeRaw: String,
        arguments: [String],
        environment: [String: String],
        signatureStatusRaw: String,
        threatLevelRaw: String,
        details: String,
        user: String
    ) {
        // Convert raw values to enums
        let eventType = ProcessEventType(rawValue: eventTypeRaw) ?? .exec
        let signatureStatus = CodeSignatureStatus(rawValue: signatureStatusRaw) ?? .unknown
        let threatLevel = ProcessThreatLevel(rawValue: threatLevelRaw) ?? .benign
        
        // Create event
        let event = ProcessEvent(
            timestamp: timestamp,
            processID: processID,
            processName: processName,
            executablePath: executablePath,
            parentProcessID: parentProcessID,
            parentProcessName: parentProcessName,
            eventType: eventType,
            arguments: arguments,
            environment: environment,
            codeSignatureStatus: signatureStatus,
            threatLevel: threatLevel,
            details: details,
            user: user,
            team: nil
        )
        
        handleProcessEvent(event)
    }
    
    func didReceiveAlert(
        timestamp: Date,
        title: String,
        message: String,
        threatLevelRaw: String,
        processID: Int32,
        processName: String
    ) {
        let threatLevel = ProcessThreatLevel(rawValue: threatLevelRaw) ?? .benign
        
        let alert = ProcessAlert(
            timestamp: timestamp,
            title: title,
            message: message,
            threatLevel: threatLevel,
            processID: processID,
            processName: processName
        )
        
        handleAlert(alert)
    }
    
    func didUpdateStatistics(totalProcesses: Int, runningProcesses: Int, suspiciousProcesses: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.stats.totalProcesses = totalProcesses
            self?.stats.runningProcesses = runningProcesses
            self?.stats.suspiciousProcesses = suspiciousProcesses
        }
    }
    
    func didEncounterError(_ error: String) {
        print("❌ Helper error: \(error)")
    }
}

// MARK: - Supporting Models

struct MonitoredProcessInfo {
    let processID: pid_t
    let processName: String
    let executablePath: String
    let parentProcessID: pid_t
    let user: String
    let signatureStatus: CodeSignatureStatus
    let threatLevel: ProcessThreatLevel
    let timestamp: Date
}

struct ProcessAlert: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let message: String
    let threatLevel: ProcessThreatLevel
    let processID: pid_t
    let processName: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
