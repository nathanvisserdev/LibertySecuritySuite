//
//  AuthorizationService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import Foundation
import LocalAuthentication
import Security

class AuthorizationService {
    private let context = LAContext()
    private var authRef: AuthorizationRef?
    private var isAuthorized = false
    
    /// Authenticate using biometrics and create authorization reference
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, String?) -> Void) {
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode
            authenticateWithPasscode(reason: reason, completion: completion)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    // Create authorization reference after successful biometric auth
                    self?.createAuthorizationRef()
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication failed"
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    /// Create an authorization reference for privileged operations
    private func createAuthorizationRef() {
        guard authRef == nil else { return }
        
        var authRefLocal: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, [], &authRefLocal)
        
        if status == errAuthorizationSuccess, let ref = authRefLocal {
            authRef = ref
            isAuthorized = true
        }
    }
    
    /// Fall back to device passcode authentication
    private func authenticateWithPasscode(reason: String, completion: @escaping (Bool, String?) -> Void) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    // Create authorization reference after successful passcode auth
                    self?.createAuthorizationRef()
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication failed"
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    /// Execute a shell command with admin privileges after biometric authentication
    func executeWithBiometricAuth(command: String, reason: String, completion: @escaping (Bool, String, String) -> Void) {
        // If already authorized, skip biometric prompt
        if isAuthorized && authRef != nil {
            let result = self.executeCommand(command: command)
            completion(result.success, result.output, result.error)
            return
        }
        
        // Otherwise, authenticate first
        authenticateWithBiometrics(reason: reason) { [weak self] success, error in
            guard let self = self else {
                completion(false, "", "Service unavailable")
                return
            }
            
            if success {
                let result = self.executeCommand(command: command)
                completion(result.success, result.output, result.error)
            } else {
                completion(false, "", error ?? "Authentication failed")
            }
        }
    }
    
    /// Invalidate authorization (e.g., after timeout or logout)
    func invalidateAuthorization() {
        if let ref = authRef {
            AuthorizationFree(ref, [])
            authRef = nil
        }
        isAuthorized = false
    }
    
    /// Execute a shell command with admin privileges using osascript (legacy password-based)
    func executeWithAdminPrompt(command: String) -> (success: Bool, output: String, error: String) {
        return executeCommand(command: command)
    }
    
    /// Internal method to execute command with admin privileges using osascript
    private func executeCommand(command: String) -> (success: Bool, output: String, error: String) {
        // Use osascript to execute with administrator privileges
        // This will prompt for password, but only after biometric auth has succeeded
        let script = """
        do shell script "\(command)" with administrator privileges
        """
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            return (task.terminationStatus == 0, output, error)
        } catch {
            return (false, "", error.localizedDescription)
        }
    }
    
    deinit {
        if let ref = authRef {
            AuthorizationFree(ref, [])
        }
    }
}

