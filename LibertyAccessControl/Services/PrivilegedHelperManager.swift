import Foundation
import Combine
import ServiceManagement
import Security

enum HelperError: Error {
    case installationFailed(String)
    case authorizationFailed(String)
    case connectionFailed(String)
    case helperNotRunning
    case versionMismatch
    
    var localizedDescription: String {
        switch self {
        case .installationFailed(let msg): return "Installation failed: \(msg)"
        case .authorizationFailed(let msg): return "Authorization failed: \(msg)"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .helperNotRunning: return "Helper tool is not running"
        case .versionMismatch: return "Helper version mismatch - reinstallation required"
        }
    }
}

class PrivilegedHelperManager: ObservableObject {
    
    @Published var installationStatus: HelperInstallationStatus = .notInstalled
    @Published var currentVersion: String?
    @Published var errorMessage: String?
    
    private var helperConnection: NSXPCConnection?
    private var delegate: PrivilegedHelperDelegateProtocol?
    
    // MARK: - Initialization
    
    init() {
        checkInstallationStatus()
    }
    
    // MARK: - Installation Status
    
    func checkInstallationStatus() {
        // Check if helper is installed by attempting to connect
        let connection = createConnection()
        
        guard let helper = connection.remoteObjectProxyWithErrorHandler({ [weak self] error in
            DispatchQueue.main.async {
                self?.installationStatus = .notInstalled
                self?.currentVersion = nil
            }
        }) as? PrivilegedHelperProtocol else {
            self.installationStatus = .notInstalled
            return
        }
        
        // Check version
        helper.getVersion { [weak self] version in
            DispatchQueue.main.async {
                self?.currentVersion = version
                if version == PrivilegedHelperInfo.version {
                    self?.installationStatus = .installed
                } else {
                    self?.installationStatus = .needsUpdate
                }
            }
        }
        
        // Check if actually running
        helper.isMonitoring { [weak self] _ in
            DispatchQueue.main.async {
                if self?.installationStatus == .notInstalled {
                    self?.installationStatus = .installedButNotRunning
                }
            }
        }
    }
    
    // MARK: - Installation
    
    func installHelper(completion: @escaping (Result<Void, HelperError>) -> Void) {
        var authRef: AuthorizationRef?
        var authItem = AuthorizationItem(
            name: kSMRightBlessPrivilegedHelper,
            valueLength: 0,
            value: nil,
            flags: 0
        )
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        
        let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
        let status = AuthorizationCreate(&authRights, nil, flags, &authRef)
        
        guard status == errAuthorizationSuccess, let authorization = authRef else {
            completion(.failure(.authorizationFailed("Failed to create authorization")))
            return
        }
        
        defer {
            AuthorizationFree(authorization, [])
        }
        
        var error: Unmanaged<CFError>?
        let result = SMJobBless(
            kSMDomainSystemLaunchd,
            PrivilegedHelperInfo.machServiceName as CFString,
            authorization,
            &error
        )
        
        if result {
            DispatchQueue.main.async {
                self.installationStatus = .installed
                self.errorMessage = nil
            }
            print("✅ Helper installed successfully")
            completion(.success(()))
        } else {
            let cfError = error?.takeRetainedValue()
            let errorDescription = cfError?.localizedDescription ?? "Unknown error"
            let errorCode = (cfError as? NSError)?.code ?? -1
            let errorDomain = (cfError as? NSError)?.domain ?? "Unknown"
            
            print("❌ SMJobBless failed:")
            print("   Error: \(errorDescription)")
            print("   Code: \(errorCode)")
            print("   Domain: \(errorDomain)")
            
            if let userInfo = (cfError as? NSError)?.userInfo {
                print("   UserInfo: \(userInfo)")
            }
            
            DispatchQueue.main.async {
                self.errorMessage = "\(errorDescription) (Code: \(errorCode))"
            }
            completion(.failure(.installationFailed("\(errorDescription) - Code: \(errorCode)")))
        }
    }
    
    // MARK: - XPC Connection
    
    func createConnection() -> NSXPCConnection {
        if let existing = helperConnection {
            return existing
        }
        
        let connection = NSXPCConnection(machServiceName: PrivilegedHelperInfo.machServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: PrivilegedHelperProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: PrivilegedHelperDelegateProtocol.self)
        connection.exportedObject = self
        
        connection.invalidationHandler = { [weak self] in
            print("❌ Helper connection invalidated")
            DispatchQueue.main.async {
                self?.helperConnection = nil
                self?.installationStatus = .installedButNotRunning
            }
        }
        
        connection.interruptionHandler = { [weak self] in
            print("⚠️ Helper connection interrupted")
            DispatchQueue.main.async {
                self?.helperConnection = nil
            }
        }
        
        connection.resume()
        self.helperConnection = connection
        
        return connection
    }
    
    func getHelper() -> PrivilegedHelperProtocol? {
        let connection = createConnection()
        return connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            print("❌ Error connecting to helper: \(error)")
            DispatchQueue.main.async {
                self?.errorMessage = "Failed to connect to helper: \(error.localizedDescription)"
            }
        } as? PrivilegedHelperProtocol
    }
    
    // MARK: - Process Monitoring Control
    
    func startProcessMonitoring(completion: @escaping (Result<Void, HelperError>) -> Void) {
        guard installationStatus == .installed else {
            completion(.failure(.helperNotRunning))
            return
        }
        
        guard let helper = getHelper() else {
            completion(.failure(.connectionFailed("Could not connect to helper")))
            return
        }
        
        helper.startProcessMonitoring { success, errorMsg in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(.connectionFailed(errorMsg ?? "Unknown error")))
            }
        }
    }
    
    func stopProcessMonitoring(completion: @escaping (Result<Void, HelperError>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(.connectionFailed("Could not connect to helper")))
            return
        }
        
        helper.stopProcessMonitoring { success in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(.connectionFailed("Failed to stop monitoring")))
            }
        }
    }
    
    func checkMonitoringStatus(completion: @escaping (Bool) -> Void) {
        guard let helper = getHelper() else {
            completion(false)
            return
        }
        
        helper.isMonitoring { isMonitoring in
            completion(isMonitoring)
        }
    }
    
    // MARK: - Delegate Registration
    
    func setDelegate(_ delegate: PrivilegedHelperDelegateProtocol) {
        self.delegate = delegate
    }
}

// MARK: - PrivilegedHelperDelegateProtocol Implementation

extension PrivilegedHelperManager: PrivilegedHelperDelegateProtocol {
    
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
        // Forward to registered delegate
        delegate?.didReceiveProcessEvent(
            timestamp: timestamp,
            processID: processID,
            processName: processName,
            executablePath: executablePath,
            parentProcessID: parentProcessID,
            parentProcessName: parentProcessName,
            eventTypeRaw: eventTypeRaw,
            arguments: arguments,
            environment: environment,
            signatureStatusRaw: signatureStatusRaw,
            threatLevelRaw: threatLevelRaw,
            details: details,
            user: user
        )
    }
    
    func didReceiveAlert(
        timestamp: Date,
        title: String,
        message: String,
        threatLevelRaw: String,
        processID: Int32,
        processName: String
    ) {
        // Forward to registered delegate
        delegate?.didReceiveAlert(
            timestamp: timestamp,
            title: title,
            message: message,
            threatLevelRaw: threatLevelRaw,
            processID: processID,
            processName: processName
        )
    }
    
    func didUpdateStatistics(totalProcesses: Int, runningProcesses: Int, suspiciousProcesses: Int) {
        // Forward to registered delegate
        delegate?.didUpdateStatistics(
            totalProcesses: totalProcesses,
            runningProcesses: runningProcesses,
            suspiciousProcesses: suspiciousProcesses
        )
    }
    
    func didEncounterError(_ error: String) {
        // Forward to registered delegate
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error
        }
        delegate?.didEncounterError(error)
    }
}
