import Foundation

// MARK: - File System Event Model
struct FileSystemEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let path: String
    let eventType: FSEventType
    let flags: FSEventFlags
    let severity: FileSystemThreatSeverity
    let details: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    var fileName: String {
        (path as NSString).lastPathComponent
    }
    
    var directory: String {
        (path as NSString).deletingLastPathComponent
    }
}

// MARK: - Event Types
enum FSEventType: String, CaseIterable {
    case created = "Created"
    case modified = "Modified"
    case deleted = "Deleted"
    case renamed = "Renamed"
    case permissionChanged = "Permission Changed"
    case attributeChanged = "Attribute Changed"
    case accessed = "Accessed"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "trash.circle.fill"
        case .renamed: return "arrow.triangle.2.circlepath.circle.fill"
        case .permissionChanged: return "lock.circle.fill"
        case .attributeChanged: return "info.circle.fill"
        case .accessed: return "eye.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .created: return "green"
        case .modified: return "blue"
        case .deleted: return "red"
        case .renamed: return "purple"
        case .permissionChanged: return "orange"
        case .attributeChanged: return "yellow"
        case .accessed: return "gray"
        case .unknown: return "gray"
        }
    }
}

// MARK: - File System Threat Severity
enum FileSystemThreatSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

// MARK: - FSEvent Flags
struct FSEventFlags: OptionSet {
    let rawValue: UInt32
    
    static let itemCreated = FSEventFlags(rawValue: 1 << 0)
    static let itemRemoved = FSEventFlags(rawValue: 1 << 1)
    static let itemModified = FSEventFlags(rawValue: 1 << 2)
    static let itemRenamed = FSEventFlags(rawValue: 1 << 3)
    static let itemChangeOwner = FSEventFlags(rawValue: 1 << 4)
    static let itemXattrMod = FSEventFlags(rawValue: 1 << 5)
    static let itemIsFile = FSEventFlags(rawValue: 1 << 6)
    static let itemIsDir = FSEventFlags(rawValue: 1 << 7)
    static let itemIsSymlink = FSEventFlags(rawValue: 1 << 8)
    
    var description: String {
        var flags: [String] = []
        if contains(.itemCreated) { flags.append("Created") }
        if contains(.itemRemoved) { flags.append("Removed") }
        if contains(.itemModified) { flags.append("Modified") }
        if contains(.itemRenamed) { flags.append("Renamed") }
        if contains(.itemChangeOwner) { flags.append("Owner Changed") }
        if contains(.itemXattrMod) { flags.append("Extended Attributes") }
        if contains(.itemIsFile) { flags.append("File") }
        if contains(.itemIsDir) { flags.append("Directory") }
        if contains(.itemIsSymlink) { flags.append("Symlink") }
        return flags.joined(separator: ", ")
    }
}

// MARK: - Monitoring Statistics
struct FileSystemStats {
    var totalEvents: Int = 0
    var eventsPerSecond: Double = 0
    var suspiciousActivities: Int = 0
    var blockedOperations: Int = 0
    var monitoredPaths: Int = 0
    var uptime: TimeInterval = 0
    
    var eventsByType: [FSEventType: Int] = [:]
    var eventsBySeverity: [FileSystemThreatSeverity: Int] = [:]
}

// MARK: - Ransomware Detection Pattern
struct RansomwarePattern {
    let rapidModificationThreshold: Int = 50 // Files modified in short time
    let timeWindow: TimeInterval = 10 // seconds
    let suspiciousExtensions: Set<String> = [".encrypted", ".locked", ".crypto", ".crypted", ".enc"]
    let massRenameThreshold: Int = 20 // Rapid renames
}

// MARK: - System File Integrity
struct SystemFileIntegrity {
    let protectedPaths: [String] = [
        "/System",
        "/Library",
        "/usr",
        "/bin",
        "/sbin",
        "/private/etc"
    ]
    
    func isProtectedPath(_ path: String) -> Bool {
        protectedPaths.contains { path.hasPrefix($0) }
    }
}
