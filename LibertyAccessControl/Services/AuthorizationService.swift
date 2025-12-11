//
//  AuthorizationService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import Foundation
import LocalAuthentication

class AuthorizationService {
    private let context = LAContext()
    
    /// Authenticate using biometrics before executing admin commands
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, String?) -> Void) {
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode
            authenticateWithPasscode(reason: reason, completion: completion)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication failed"
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    /// Fall back to device passcode authentication
    private func authenticateWithPasscode(reason: String, completion: @escaping (Bool, String?) -> Void) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
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
    
    /// Execute a shell command with admin privileges using osascript (legacy password-based)
    func executeWithAdminPrompt(command: String) -> (success: Bool, output: String, error: String) {
        return executeCommand(command: command)
    }
    
    /// Internal method to execute command with admin privileges
    private func executeCommand(command: String) -> (success: Bool, output: String, error: String) {
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
}
