import Foundation

// MARK: - Process Event Model
struct ProcessEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let processID: pid_t
    let processName: String
    let executablePath: String
    let parentProcessID: pid_t
    let parentProcessName: String
    let eventType: ProcessEventType
    let arguments: [String]
    let environment: [String: String]
    let codeSignatureStatus: CodeSignatureStatus
    let threatLevel: ProcessThreatLevel
    let details: String
    let user: String
    let team: String?
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    var fullCommand: String {
        ([executablePath] + arguments).joined(separator: " ")
    }
}

// MARK: - Process Event Types
enum ProcessEventType: String, CaseIterable {
    case exec = "Process Execution"
    case fork = "Process Fork"
    case exit = "Process Exit"
    case signal = "Signal Received"
    case injection = "Code Injection"
    case memoryModification = "Memory Modification"
    case privilegeEscalation = "Privilege Escalation"
    
    var icon: String {
        switch self {
        case .exec: return "arrow.triangle.2.circlepath"
        case .fork: return "arrow.triangle.branch"
        case .exit: return "xmark.circle"
        case .signal: return "bolt.circle"
        case .injection: return "syringe"
        case .memoryModification: return "memorychip"
        case .privilegeEscalation: return "arrow.up.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .exec: return "blue"
        case .fork: return "purple"
        case .exit: return "gray"
        case .signal: return "orange"
        case .injection: return "red"
        case .memoryModification: return "red"
        case .privilegeEscalation: return "red"
        }
    }
}

// MARK: - Code Signature Status
enum CodeSignatureStatus: String, CaseIterable {
    case valid = "Valid"
    case invalid = "Invalid"
    case notSigned = "Not Signed"
    case adhoc = "Ad-hoc Signed"
    case unknown = "Unknown"
    case revoked = "Revoked"
    
    var icon: String {
        switch self {
        case .valid: return "checkmark.seal.fill"
        case .invalid: return "xmark.seal.fill"
        case .notSigned: return "questionmark.circle"
        case .adhoc: return "signature"
        case .unknown: return "questionmark.circle.fill"
        case .revoked: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: String {
        switch self {
        case .valid: return "green"
        case .invalid: return "red"
        case .notSigned: return "orange"
        case .adhoc: return "yellow"
        case .unknown: return "gray"
        case .revoked: return "red"
        }
    }
    
    var isSuspicious: Bool {
        switch self {
        case .invalid, .revoked: return true
        case .notSigned: return true
        default: return false
        }
    }
}

// MARK: - Process Threat Level
enum ProcessThreatLevel: String, CaseIterable {
    case benign = "Benign"
    case suspicious = "Suspicious"
    case malicious = "Malicious"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .benign: return "green"
        case .suspicious: return "yellow"
        case .malicious: return "orange"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .benign: return "checkmark.shield.fill"
        case .suspicious: return "exclamationmark.shield.fill"
        case .malicious: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Process Statistics
struct ProcessStats {
    var totalProcesses: Int = 0
    var runningProcesses: Int = 0
    var suspiciousProcesses: Int = 0
    var blockedProcesses: Int = 0
    var injectionAttempts: Int = 0
    var privilegeEscalations: Int = 0
    
    var eventsByType: [ProcessEventType: Int] = [:]
    var eventsByThreat: [ProcessThreatLevel: Int] = [:]
    var signatureStats: [CodeSignatureStatus: Int] = [:]
}

// MARK: - Process Tree Node
struct ProcessTreeNode: Identifiable {
    let id = UUID()
    let processID: pid_t
    let processName: String
    let executablePath: String
    let parentID: pid_t
    var children: [ProcessTreeNode] = []
    let timestamp: Date
    let threatLevel: ProcessThreatLevel
}

// MARK: - Suspicious Process Patterns
struct SuspiciousProcessPattern {
    // Known malware process names
    static let malwareProcessNames: Set<String> = [
        "miner", "cryptominer", "xmrig", "coinminer",
        "backdoor", "trojan", "keylogger", "rootkit"
    ]
    
    // Suspicious parent-child relationships
    static let suspiciousParents: Set<String> = [
        "launchd", "sudo", "bash", "sh", "zsh"
    ]
    
    // Critical system directories that shouldn't spawn unusual processes
    static let protectedPaths: Set<String> = [
        "/System", "/usr/bin", "/usr/sbin", "/bin", "/sbin"
    ]
    
    // Suspicious arguments
    static let suspiciousArguments: [String] = [
        "-p", "--password", "curl", "wget", "nc", "netcat",
        "base64", "eval", "exec", "/dev/tcp"
    ]
    
    // Injection indicators
    static let injectionIndicators: [String] = [
        "DYLD_INSERT_LIBRARIES", "DYLD_FORCE_FLAT_NAMESPACE",
        "DYLD_LIBRARY_PATH", "dylib"
    ]
    
    // Known legitimate Apple processes (whitelist)
    static let appleProcesses: Set<String> = [
        "com.apple.", "WindowServer", "Finder", "Dock", "SystemUIServer",
        "kernel_task", "launchd", "syslogd", "kextd"
    ]
}

// MARK: - Process Injection Detection
struct InjectionDetection {
    let processID: pid_t
    let injectionType: InjectionType
    let targetProcess: String
    let sourceProcess: String?
    let timestamp: Date
    
    enum InjectionType: String {
        case dylibInjection = "Dylib Injection"
        case processHollowing = "Process Hollowing"
        case threadInjection = "Thread Injection"
        case memoryPatching = "Memory Patching"
        case unknown = "Unknown Injection"
    }
}

// MARK: - Privilege Escalation Detection
struct PrivilegeEscalation {
    let processID: pid_t
    let processName: String
    let originalUID: uid_t
    let newUID: uid_t
    let method: EscalationMethod
    let timestamp: Date
    
    enum EscalationMethod: String {
        case sudo = "sudo"
        case setuid = "setuid binary"
        case exploit = "Exploit"
        case unknown = "Unknown"
    }
    
    var isRootEscalation: Bool {
        return newUID == 0 && originalUID != 0
    }
}
