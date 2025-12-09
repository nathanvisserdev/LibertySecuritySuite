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
        // Check if user was previously authenticated in this session
        let wasAuthenticated = UserDefaults.standard.bool(forKey: authKey)
        
        if wasAuthenticated {
            status = .authenticated
        } else {
            status = .unauthenticated
            showingAuthSheet = true
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
                    UserDefaults.standard.set(true, forKey: self?.authKey ?? "")
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
                    UserDefaults.standard.set(true, forKey: self?.authKey ?? "")
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
        UserDefaults.standard.set(false, forKey: authKey)
        
        // Clear any cached data
        UserDefaults.standard.synchronize()
    }
    
    func retryAuthentication() {
        authenticate { _, _ in }
    }
}
