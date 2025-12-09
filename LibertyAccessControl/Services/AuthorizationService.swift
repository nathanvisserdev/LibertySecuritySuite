//
//  AuthorizationService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import Foundation

class AuthorizationService {
    
    /// Execute a shell command with admin privileges using osascript
    func executeWithAdminPrompt(command: String) -> (success: Bool, output: String, error: String) {
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
