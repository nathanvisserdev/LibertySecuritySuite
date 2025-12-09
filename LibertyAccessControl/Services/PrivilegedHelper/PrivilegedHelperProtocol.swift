import Foundation

// MARK: - XPC Protocol for Main App → Helper Communication

@objc(PrivilegedHelperProtocol)
protocol PrivilegedHelperProtocol {
    /// Start process monitoring
    func startProcessMonitoring(reply: @escaping (Bool, String?) -> Void)
    
    /// Stop process monitoring
    func stopProcessMonitoring(reply: @escaping (Bool) -> Void)
    
    /// Check if monitoring is active
    func isMonitoring(reply: @escaping (Bool) -> Void)
    
    /// Get version of helper tool
    func getVersion(reply: @escaping (String) -> Void)
}

// MARK: - XPC Protocol for Helper → Main App Communication

@objc(PrivilegedHelperDelegateProtocol)
protocol PrivilegedHelperDelegateProtocol {
    /// Send process event to main app
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
    )
    
    /// Send alert to main app
    func didReceiveAlert(
        timestamp: Date,
        title: String,
        message: String,
        threatLevelRaw: String,
        processID: Int32,
        processName: String
    )
    
    /// Send statistics update
    func didUpdateStatistics(
        totalProcesses: Int,
        runningProcesses: Int,
        suspiciousProcesses: Int
    )
    
    /// Report error
    func didEncounterError(_ error: String)
}

// MARK: - Helper Info

struct PrivilegedHelperInfo {
    static let machServiceName = "com.liberty.LibertyAccessControl.helper"
    static let version = "1.0.0"
    static let minimumAppVersion = "1.0.0"
}

// MARK: - Helper Installation Status

enum HelperInstallationStatus {
    case notInstalled
    case installed
    case needsUpdate
    case installedButNotRunning
    
    var description: String {
        switch self {
        case .notInstalled: return "Not Installed"
        case .installed: return "Installed & Running"
        case .needsUpdate: return "Needs Update"
        case .installedButNotRunning: return "Installed but Not Running"
        }
    }
}
