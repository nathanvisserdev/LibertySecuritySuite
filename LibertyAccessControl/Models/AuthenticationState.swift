//
//  AuthenticationState.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Combine
import LocalAuthentication

enum AuthenticationStatus: Equatable {
    case authenticated
    case unauthenticated
    case authenticating
    case failed(String)
}

class AuthenticationState: ObservableObject {
    @Published var status: AuthenticationStatus = .unauthenticated
    @Published var showingAuthSheet = false
    
    private let context = LAContext()
    private let authKey = "com.libertyaccesscontrol.authenticated"
    
    func checkAuthenticationStatus() {
        // Always require authentication at launch - never persist auth state
        status = .unauthenticated
        showingAuthSheet = true
        
        // Automatically trigger biometric authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.authenticate { success, error in
                if !success {
                    let msg = "⚠️ Biometric authentication failed at launch: \(error ?? "Unknown error")"
                    print(msg)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SystemLogMessage"),
                        object: nil,
                        userInfo: ["message": msg, "type": SystemMessage.MessageType.warning]
                    )
                }
            }
        }
    }
    
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        status = .authenticating
        
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode
            authenticateWithPasscode(completion: completion)
            return
        }
        
        let reason = "Authenticate to access Liberty Access Control"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    self?.status = .authenticated
                    self?.showingAuthSheet = false
                    // Don't persist authentication - require it every launch
                    let successMsg = "✅ Biometric authentication successful"
                    print(successMsg)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SystemLogMessage"),
                        object: nil,
                        userInfo: ["message": successMsg, "type": SystemMessage.MessageType.success]
                    )
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication failed"
                    self?.status = .failed(errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    private func authenticateWithPasscode(completion: @escaping (Bool, String?) -> Void) {
        let reason = "Authenticate to access Liberty Access Control"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    self?.status = .authenticated
                    self?.showingAuthSheet = false
                    // Don't persist authentication - require it every launch
                    let successMsg = "✅ Passcode authentication successful"
                    print(successMsg)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SystemLogMessage"),
                        object: nil,
                        userInfo: ["message": successMsg, "type": SystemMessage.MessageType.success]
                    )
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication failed"
                    self?.status = .failed(errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    func logout() {
        status = .unauthenticated
        showingAuthSheet = true
        // No need to clear UserDefaults since we don't persist auth state anymore
    }
    
    func retryAuthentication() {
        authenticate { _, _ in }
    }
}
