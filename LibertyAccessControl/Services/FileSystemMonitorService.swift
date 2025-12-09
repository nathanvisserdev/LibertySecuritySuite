import Foundation
import Combine

class FileSystemMonitorService: ObservableObject {
    static let shared = FileSystemMonitorService()
    
    @Published var events: [FileSystemEvent] = []
    @Published var stats: FileSystemStats = FileSystemStats()
    @Published var isMonitoring: Bool = false
    @Published var alerts: [FileSystemAlert] = []
    
    private var eventStream: FSEventStreamRef?
    private var monitoredPaths: [String] = []
    private var eventQueue = DispatchQueue(label: "com.liberty.filesystemmonitor", qos: .userInitiated)
    private var statsTimer: Timer?
    private var recentEvents: [(path: String, timestamp: Date)] = []
    private let maxStoredEvents = 1000
    
    // Ransomware detection
    private let ransomwarePattern = RansomwarePattern()
    private var fileModificationTracker: [String: [Date]] = [:]
    
    // System integrity
    private let systemIntegrity = SystemFileIntegrity()
    
    // Persistence
    private let persistenceController = FileSystemPersistenceController.shared
    private var persistenceTimer: Timer?
    
    private init() {
        // Load persisted events on initialization
        loadPersistedData()
    }
    
    // MARK: - Start/Stop Monitoring
    func startMonitoring(paths: [String] = []) {
        guard !isMonitoring else { return }
        
        // Default to monitoring user home directory and common locations
        monitoredPaths = paths.isEmpty ? getDefaultMonitoredPaths() : paths
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: FSEventStreamCallback = { (
            streamRef: ConstFSEventStreamRef,
            clientCallBackInfo: UnsafeMutableRawPointer?,
            numEvents: Int,
            eventPaths: UnsafeMutableRawPointer,
            eventFlags: UnsafePointer<FSEventStreamEventFlags>,
            eventIds: UnsafePointer<FSEventStreamEventId>
        ) in
            let service = Unmanaged<FileSystemMonitorService>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]
            
            for i in 0..<numEvents {
                service.handleFSEvent(
                    path: paths[i],
                    flags: eventFlags[i],
                    eventId: eventIds[i]
                )
            }
        }
        
        let pathsToWatch = monitoredPaths as CFArray
        let latency: CFTimeInterval = 0.3 // 300ms latency for better performance
        
        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer)
        )
        
        if let stream = eventStream {
            FSEventStreamSetDispatchQueue(stream, eventQueue)
            FSEventStreamStart(stream)
            
            DispatchQueue.main.async {
                self.isMonitoring = true
                self.stats.monitoredPaths = self.monitoredPaths.count
                self.startStatsTimer()
                self.startPersistenceTimer()
            }
            
            print("📁 File System Monitoring started for \(monitoredPaths.count) paths")
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring, let stream = eventStream else { return }
        
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil
        
        DispatchQueue.main.async {
            self.isMonitoring = false
            self.statsTimer?.invalidate()
            self.statsTimer = nil
            self.persistenceTimer?.invalidate()
            self.persistenceTimer = nil
            
            // Final save before stopping
            self.persistCurrentData()
        }
        
        print("📁 File System Monitoring stopped")
    }
    
    // MARK: - Event Handling
    private func handleFSEvent(path: String, flags: FSEventStreamEventFlags, eventId: FSEventStreamEventId) {
        let timestamp = Date()
        
        // Convert FSEvent flags to our custom flags
        var customFlags = FSEventFlags()
        if (flags & UInt32(kFSEventStreamEventFlagItemCreated)) != 0 { customFlags.insert(.itemCreated) }
        if (flags & UInt32(kFSEventStreamEventFlagItemRemoved)) != 0 { customFlags.insert(.itemRemoved) }
        if (flags & UInt32(kFSEventStreamEventFlagItemModified)) != 0 { customFlags.insert(.itemModified) }
        if (flags & UInt32(kFSEventStreamEventFlagItemRenamed)) != 0 { customFlags.insert(.itemRenamed) }
        if (flags & UInt32(kFSEventStreamEventFlagItemChangeOwner)) != 0 { customFlags.insert(.itemChangeOwner) }
        if (flags & UInt32(kFSEventStreamEventFlagItemXattrMod)) != 0 { customFlags.insert(.itemXattrMod) }
        if (flags & UInt32(kFSEventStreamEventFlagItemIsFile)) != 0 { customFlags.insert(.itemIsFile) }
        if (flags & UInt32(kFSEventStreamEventFlagItemIsDir)) != 0 { customFlags.insert(.itemIsDir) }
        if (flags & UInt32(kFSEventStreamEventFlagItemIsSymlink)) != 0 { customFlags.insert(.itemIsSymlink) }
        
        // Determine event type
        let eventType = determineEventType(flags: customFlags)
        
        // Analyze threat level
        let (severity, details) = analyzeThreatLevel(path: path, eventType: eventType, flags: customFlags)
        
        // Create event
        let event = FileSystemEvent(
            timestamp: timestamp,
            path: path,
            eventType: eventType,
            flags: customFlags,
            severity: severity,
            details: details
        )
        
        // Track for ransomware detection
        trackForRansomware(path: path, timestamp: timestamp, eventType: eventType)
        
        // Update UI on main thread
        DispatchQueue.main.async {
            self.addEvent(event)
            self.updateStats(event: event)
            
            // Generate alerts for high severity events
            if severity == .high || severity == .critical {
                self.generateAlert(event: event)
            }
        }
    }
    
    private func determineEventType(flags: FSEventFlags) -> FSEventType {
        if flags.contains(.itemCreated) { return .created }
        if flags.contains(.itemRemoved) { return .deleted }
        if flags.contains(.itemRenamed) { return .renamed }
        if flags.contains(.itemModified) { return .modified }
        if flags.contains(.itemChangeOwner) { return .permissionChanged }
        if flags.contains(.itemXattrMod) { return .attributeChanged }
        return .unknown
    }
    
    private func analyzeThreatLevel(path: String, eventType: FSEventType, flags: FSEventFlags) -> (severity: FileSystemThreatSeverity, details: String) {
        var severity: FileSystemThreatSeverity = .low
        var details: [String] = []
        
        // Check if system file
        if systemIntegrity.isProtectedPath(path) {
            severity = .critical
            details.append("System file modification detected")
        }
        
        // Check for suspicious extensions
        let fileExtension = (path as NSString).pathExtension
        if ransomwarePattern.suspiciousExtensions.contains("." + fileExtension) {
            severity = .critical
            details.append("Suspicious file extension: .\(fileExtension)")
        }
        
        // Check for rapid modifications (potential ransomware)
        if let modifications = fileModificationTracker[path], modifications.count > 10 {
            let recentMods = modifications.filter { Date().timeIntervalSince($0) < 30 }
            if recentMods.count > 5 {
                severity = .high
                details.append("Rapid file modifications detected")
            }
        }
        
        // Permission changes on system files
        if eventType == .permissionChanged && systemIntegrity.isProtectedPath(path) {
            severity = .critical
            details.append("Unauthorized permission change on system file")
        }
        
        // Mass deletions
        if eventType == .deleted {
            let recentDeletions = recentEvents.filter {
                $0.timestamp.timeIntervalSinceNow > -5 // Last 5 seconds
            }.count
            if recentDeletions > 20 {
                severity = .high
                details.append("Mass file deletion detected")
            }
        }
        
        if details.isEmpty {
            details.append("Normal file system operation")
        }
        
        return (severity, details.joined(separator: "; "))
    }
    
    // MARK: - Ransomware Detection
    private func trackForRansomware(path: String, timestamp: Date, eventType: FSEventType) {
        guard eventType == .modified || eventType == .renamed else { return }
        
        // Track modifications
        if fileModificationTracker[path] == nil {
            fileModificationTracker[path] = []
        }
        fileModificationTracker[path]?.append(timestamp)
        
        // Keep only recent modifications
        fileModificationTracker[path] = fileModificationTracker[path]?.filter {
            timestamp.timeIntervalSince($0) < ransomwarePattern.timeWindow
        }
        
        // Check for ransomware pattern
        if let mods = fileModificationTracker[path],
           mods.count >= ransomwarePattern.rapidModificationThreshold {
            DispatchQueue.main.async {
                self.generateRansomwareAlert(path: path, modificationCount: mods.count)
            }
        }
        
        // Track in recent events for pattern analysis
        recentEvents.append((path: path, timestamp: timestamp))
        
        // Keep only recent events (last 60 seconds)
        recentEvents = recentEvents.filter { timestamp.timeIntervalSince($0.timestamp) < 60 }
    }
    
    private func generateRansomwareAlert(path: String, modificationCount: Int) {
        let alert = FileSystemAlert(
            timestamp: Date(),
            title: "⚠️ RANSOMWARE ACTIVITY DETECTED",
            message: "Suspicious rapid file modifications detected: \(modificationCount) changes to \(path) in \(Int(ransomwarePattern.timeWindow)) seconds",
            severity: .critical,
            path: path
        )
        alerts.insert(alert, at: 0)
        stats.suspiciousActivities += 1
        
        // Optionally trigger system notification
        // Note: Uncomment if NotificationService is available
        // NotificationService.shared.sendNotification(
        //     title: "Critical Security Alert",
        //     body: alert.message
        // )
    }
    
    private func generateAlert(event: FileSystemEvent) {
        let alert = FileSystemAlert(
            timestamp: event.timestamp,
            title: "Security Event: \(event.eventType.rawValue)",
            message: event.details,
            severity: event.severity,
            path: event.path
        )
        alerts.insert(alert, at: 0)
        
        // Save to persistence
        persistenceController.saveAlert(alert)
        
        // Keep only recent alerts
        if alerts.count > 100 {
            alerts = Array(alerts.prefix(100))
        }
    }
    
    // MARK: - Event Management
    private func addEvent(_ event: FileSystemEvent) {
        events.insert(event, at: 0)
        
        // Save to persistence (high/critical severity immediately)
        if event.severity == .high || event.severity == .critical {
            persistenceController.saveEvent(event)
        }
        
        // Limit stored events
        if events.count > maxStoredEvents {
            events = Array(events.prefix(maxStoredEvents))
        }
    }
    
    private func updateStats(event: FileSystemEvent) {
        stats.totalEvents += 1
        
        // Update by type
        stats.eventsByType[event.eventType, default: 0] += 1
        
        // Update by severity
        stats.eventsBySeverity[event.severity, default: 0] += 1
        
        if event.severity == .high || event.severity == .critical {
            stats.suspiciousActivities += 1
        }
    }
    
    // MARK: - Statistics
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.stats.uptime += 1
            
            // Calculate events per second
            let recentEvents = self.events.filter { $0.timestamp.timeIntervalSinceNow > -1 }
            self.stats.eventsPerSecond = Double(recentEvents.count)
        }
    }
    
    // MARK: - Utilities
    private func getDefaultMonitoredPaths() -> [String] {
        var paths: [String] = []
        
        // User home directory
        if let homeDir = FileManager.default.urls(for: .userDirectory, in: .localDomainMask).first?.path {
            paths.append(homeDir)
        }
        
        // Documents
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            paths.append(docsDir)
        }
        
        // Desktop
        if let desktopDir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path {
            paths.append(desktopDir)
        }
        
        // Downloads
        if let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path {
            paths.append(downloadsDir)
        }
        
        return paths
    }
    
    func clearEvents() {
        events.removeAll()
        alerts.removeAll()
        stats = FileSystemStats()
        stats.monitoredPaths = monitoredPaths.count
        
        // Clear from persistence
        persistenceController.deleteAllEvents()
    }
    
    func clearAlerts() {
        alerts.removeAll()
        
        // Clear from persistence
        persistenceController.deleteAllAlerts()
    }
    
    // MARK: - Persistence
    
    private func loadPersistedData() {
        // Load recent events (last 7 days)
        let persistedEvents = persistenceController.fetchEvents(limit: maxStoredEvents)
        
        DispatchQueue.main.async {
            self.events = persistedEvents
            
            // Recalculate stats from persisted data
            self.recalculateStats()
        }
        
        // Load recent alerts
        let persistedAlerts = persistenceController.fetchAlerts(limit: 100)
        
        DispatchQueue.main.async {
            self.alerts = persistedAlerts
        }
        
        print("📂 Loaded \(persistedEvents.count) events and \(persistedAlerts.count) alerts from persistence")
    }
    
    private func persistCurrentData() {
        // Batch save all current events that aren't already saved
        let eventsToSave = events.filter { event in
            // Only save if not high/critical (those are saved immediately)
            event.severity != .high && event.severity != .critical
        }
        
        if !eventsToSave.isEmpty {
            persistenceController.saveEvents(eventsToSave)
            print("💾 Persisted \(eventsToSave.count) events")
        }
    }
    
    private func startPersistenceTimer() {
        // Save data every 5 minutes
        persistenceTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.persistCurrentData()
        }
    }
    
    private func recalculateStats() {
        // Recalculate statistics from loaded events
        for event in events {
            stats.totalEvents += 1
            stats.eventsByType[event.eventType, default: 0] += 1
            stats.eventsBySeverity[event.severity, default: 0] += 1
            
            if event.severity == .high || event.severity == .critical {
                stats.suspiciousActivities += 1
            }
        }
    }
    
    // MARK: - Data Retention
    
    func cleanupOldData(olderThanDays days: Int = 30) {
        persistenceController.deleteOldEvents(olderThanDays: days)
        persistenceController.deleteOldAlerts(olderThanDays: days)
        
        // Reload data after cleanup
        loadPersistedData()
        
        print("🧹 Cleaned up data older than \(days) days")
    }
}

// MARK: - Alert Model
struct FileSystemAlert: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let message: String
    let severity: FileSystemThreatSeverity
    let path: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
