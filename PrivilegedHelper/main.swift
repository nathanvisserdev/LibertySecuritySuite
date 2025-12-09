import Foundation
import EndpointSecurity
import Security
import Darwin

class PrivilegedHelper: NSObject, NSXPCListenerDelegate, PrivilegedHelperProtocol {
    
    private var listener: NSXPCListener?
    private var connections: [NSXPCConnection] = []
    private var esClient: OpaquePointer?
    private var isMonitoringActive = false
    
    // MARK: - Lifecycle
    
    func run() {
        let listener = NSXPCListener(machServiceName: PrivilegedHelperInfo.machServiceName)
        listener.delegate = self
        self.listener = listener
        listener.resume()
        
        print("✅ Privileged helper started: \(PrivilegedHelperInfo.machServiceName)")
        RunLoop.main.run()
    }
    
    // MARK: - NSXPCListenerDelegate
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Set up the connection
        newConnection.exportedInterface = NSXPCInterface(with: PrivilegedHelperProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: PrivilegedHelperDelegateProtocol.self)
        
        newConnection.invalidationHandler = { [weak self] in
            self?.connections.removeAll { $0 == newConnection }
            print("❌ XPC connection invalidated")
        }
        
        newConnection.interruptionHandler = {
            print("⚠️ XPC connection interrupted")
        }
        
        connections.append(newConnection)
        newConnection.resume()
        
        print("✅ Accepted XPC connection from main app")
        return true
    }
    
    // MARK: - PrivilegedHelperProtocol
    
    func startProcessMonitoring(reply: @escaping (Bool, String?) -> Void) {
        guard !isMonitoringActive else {
            reply(true, nil)
            return
        }
        
        // Create ES client
        let result = es_new_client(&esClient) { [weak self] client, message in
            self?.handleESMessage(message.pointee)
        }
        
        guard result == ES_NEW_CLIENT_RESULT_SUCCESS else {
            let errorMsg = "Failed to create EndpointSecurity client: \(result.rawValue)"
            print("❌ \(errorMsg)")
            reply(false, errorMsg)
            return
        }
        
        // Subscribe to events
        let events: [es_event_type_t] = [
            ES_EVENT_TYPE_NOTIFY_EXEC,
            ES_EVENT_TYPE_NOTIFY_FORK,
            ES_EVENT_TYPE_NOTIFY_EXIT,
            ES_EVENT_TYPE_NOTIFY_SIGNAL,
        ]
        
        let subscribeResult = es_subscribe(esClient!, events, UInt32(events.count))
        
        if subscribeResult == ES_RETURN_SUCCESS {
            isMonitoringActive = true
            print("✅ Process monitoring started in privileged helper")
            reply(true, nil)
        } else {
            let errorMsg = "Failed to subscribe to events: \(subscribeResult.rawValue)"
            print("❌ \(errorMsg)")
            if let client = esClient {
                es_delete_client(client)
                esClient = nil
            }
            reply(false, errorMsg)
        }
    }
    
    func stopProcessMonitoring(reply: @escaping (Bool) -> Void) {
        guard isMonitoringActive, let client = esClient else {
            reply(true)
            return
        }
        
        es_unsubscribe_all(client)
        es_delete_client(client)
        esClient = nil
        isMonitoringActive = false
        
        print("⏹️ Process monitoring stopped in privileged helper")
        reply(true)
    }
    
    func isMonitoring(reply: @escaping (Bool) -> Void) {
        reply(isMonitoringActive)
    }
    
    func getVersion(reply: @escaping (String) -> Void) {
        reply(PrivilegedHelperInfo.version)
    }
    
    // MARK: - EndpointSecurity Message Handling
    
    private func handleESMessage(_ message: es_message_t) {
        switch message.event_type {
        case ES_EVENT_TYPE_NOTIFY_EXEC:
            handleExecEvent(message)
        case ES_EVENT_TYPE_NOTIFY_FORK:
            handleForkEvent(message)
        case ES_EVENT_TYPE_NOTIFY_EXIT:
            handleExitEvent(message)
        case ES_EVENT_TYPE_NOTIFY_SIGNAL:
            handleSignalEvent(message)
        default:
            break
        }
    }
    
    private func handleExecEvent(_ message: es_message_t) {
        let exec = message.event.exec
        let process = message.process.pointee
        
        // Extract process information
        let processID = audit_token_to_pid(process.audit_token)
        let processName = String(cString: process.executable.pointee.path.data)
        let executablePath = processName
        
        let parentID = process.ppid
        let parentName = getProcessName(pid: parentID)
        
        let arguments = extractArguments(exec: exec)
        let environment = extractEnvironment(exec: exec)
        
        let uid = process.audit_token.val.6
        let user = getUserName(uid: uid)
        
        let signatureStatus = validateCodeSignature(path: executablePath)
        let (threatLevel, details) = analyzeThreat(
            processName: processName,
            path: executablePath,
            arguments: arguments,
            environment: environment,
            signatureStatus: signatureStatus
        )
        
        // Send to all connected clients
        for connection in connections {
            if let proxy = connection.remoteObjectProxy as? PrivilegedHelperDelegateProtocol {
                proxy.didReceiveProcessEvent(
                    timestamp: Date(),
                    processID: processID,
                    processName: (processName as NSString).lastPathComponent,
                    executablePath: executablePath,
                    parentProcessID: parentID,
                    parentProcessName: parentName,
                    eventTypeRaw: "exec",
                    arguments: arguments,
                    environment: environment,
                    signatureStatusRaw: signatureStatus,
                    threatLevelRaw: threatLevel,
                    details: details,
                    user: user
                )
                
                // Send alert if threat detected
                if threatLevel == "malicious" || threatLevel == "critical" {
                    proxy.didReceiveAlert(
                        timestamp: Date(),
                        title: "⚠️ \(threatLevel.uppercased()) PROCESS DETECTED",
                        message: "\((processName as NSString).lastPathComponent) (PID: \(processID)): \(details)",
                        threatLevelRaw: threatLevel,
                        processID: processID,
                        processName: (processName as NSString).lastPathComponent
                    )
                }
            }
        }
    }
    
    private func handleForkEvent(_ message: es_message_t) {
        // Handle fork events if needed
    }
    
    private func handleExitEvent(_ message: es_message_t) {
        // Handle exit events if needed
    }
    
    private func handleSignalEvent(_ message: es_message_t) {
        // Handle signal events if needed
    }
    
    // MARK: - Helper Methods (copied from ProcessMonitorService)
    
    private func extractArguments(exec: es_event_exec_t) -> [String] {
        var args: [String] = []
        var execCopy = exec
        let count = Int(es_exec_arg_count(&execCopy))
        
        for i in 0..<count {
            let arg = es_exec_arg(&execCopy, UInt32(i))
            let argString = String(cString: arg.data)
            args.append(argString)
        }
        
        return args
    }
    
    private func extractEnvironment(exec: es_event_exec_t) -> [String: String] {
        var env: [String: String] = [:]
        var execCopy = exec
        let count = Int(es_exec_env_count(&execCopy))
        
        for i in 0..<count {
            let envVar = es_exec_env(&execCopy, UInt32(i))
            let envString = String(cString: envVar.data)
            let parts = envString.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                env[String(parts[0])] = String(parts[1])
            }
        }
        
        return env
    }
    
    private func getProcessName(pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 4096)
        let ret = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        
        if ret > 0 {
            let path = String(cString: buffer)
            return (path as NSString).lastPathComponent
        }
        
        return "unknown"
    }
    
    private func getUserName(uid: uid_t) -> String {
        if let passwd = getpwuid(uid) {
            return String(cString: passwd.pointee.pw_name)
        }
        return "uid:\(uid)"
    }
    
    private func validateCodeSignature(path: String) -> String {
        guard let code = createStaticCode(path: path) else {
            return "unknown"
        }
        
        var requirement: SecRequirement?
        let reqResult = SecRequirementCreateWithString(
            "anchor apple generic" as CFString,
            [],
            &requirement
        )
        
        let status = SecStaticCodeCheckValidity(code, [], requirement)
        
        switch status {
        case errSecSuccess: return "valid"
        case errSecCSUnsigned: return "notSigned"
        case errSecCSSignatureFailed, errSecCSSignatureInvalid: return "invalid"
        default: return "unknown"
        }
    }
    
    private func createStaticCode(path: String) -> SecStaticCode? {
        var staticCode: SecStaticCode?
        let url = URL(fileURLWithPath: path) as CFURL
        let status = SecStaticCodeCreateWithPath(url, [], &staticCode)
        return status == errSecSuccess ? staticCode : nil
    }
    
    private func analyzeThreat(
        processName: String,
        path: String,
        arguments: [String],
        environment: [String: String],
        signatureStatus: String
    ) -> (String, String) {
        var threatLevel = "benign"
        var reasons: [String] = []
        
        if signatureStatus == "invalid" || signatureStatus == "notSigned" {
            threatLevel = "suspicious"
            reasons.append("Unsigned or invalid code signature")
        }
        
        let lowerName = processName.lowercased()
        let malwareNames = ["miner", "cryptominer", "xmrig", "backdoor", "trojan", "keylogger"]
        for malware in malwareNames {
            if lowerName.contains(malware) {
                threatLevel = "critical"
                reasons.append("Known malware process name: \(malware)")
            }
        }
        
        if path.contains("/tmp") || path.contains("/var/tmp") {
            if threatLevel == "benign" {
                threatLevel = "suspicious"
            }
            reasons.append("Running from temporary directory")
        }
        
        if reasons.isEmpty {
            reasons.append("Normal process execution")
        }
        
        return (threatLevel, reasons.joined(separator: "; "))
    }
}

// MARK: - Main Entry Point

autoreleasepool {
    let helper = PrivilegedHelper()
    helper.run()
}
