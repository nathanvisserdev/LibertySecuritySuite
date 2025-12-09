//
//  AuthenticationView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Liberty Access Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Secure TCC Permission Management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Authentication Status
            VStack(spacing: 20) {
                if case .failed(let message) = authState.status {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(message)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Authenticate Button
                Button(action: authenticateUser) {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "faceid")
                                .font(.title2)
                        }
                        
                        Text(isAuthenticating ? "Authenticating..." : "Authenticate with Touch ID / Face ID")
                            .font(.headline)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isAuthenticating)
                
                // Alternative authentication methods
                VStack(spacing: 12) {
                    Text("Alternative Methods")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        Button(action: authenticateWithPasscode) {
                            VStack(spacing: 8) {
                                Image(systemName: "key.fill")
                                    .font(.title2)
                                Text("Passcode")
                                    .font(.caption)
                            }
                            .frame(width: 100, height: 80)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: authenticateWithSystemAuth) {
                            VStack(spacing: 8) {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.title2)
                                Text("System Auth")
                                    .font(.caption)
                            }
                            .frame(width: 100, height: 80)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top)
            }
            
            Spacer()
            
            // Security Notice
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Secure Authentication Required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("This app manages sensitive system permissions and requires authentication to access.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func authenticateUser() {
        isAuthenticating = true
        errorMessage = nil
        
        authState.authenticate { success, error in
            isAuthenticating = false
            if let error = error {
                errorMessage = error
            }
        }
    }
    
    private func authenticateWithPasscode() {
        authenticateUser()
    }
    
    private func authenticateWithSystemAuth() {
        authenticateUser()
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationState())
}
