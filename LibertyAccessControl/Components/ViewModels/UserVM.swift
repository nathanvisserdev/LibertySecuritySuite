//
//  UserVM.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import Security

class UserVM: ObservableObject {
    @Published var statusMessage: String = "User TCC Database - Ready to query"
    @Published var errorMessage: String?
    @Published var entries: [UserEntry] = []
    @Published var isLoading: Bool = false
    
    private let model: UserModel
    private let userService: UserService
    private let blacklistService: BlacklistService
    private var codeSignature: String?
    
    var appCodeSignature: String {
        return codeSignature ?? "Unable to calculate"
    }
    
    init(UserService: UserService = UserService(), blacklistService: BlacklistService = .shared) {
        self.model = UserModel(UserService: UserService)
        self.userService = UserService
        self.blacklistService = blacklistService
        self.codeSignature = calculateCodeSignature()
    }
    
    private func calculateCodeSignature() -> String? {
        var code: SecCode?
        var status = SecCodeCopySelf([], &code)
        
        guard status == errSecSuccess, let code = code else {
            print("Failed to get SecCode: \(status)")
            return nil
        }
        
        // Convert SecCode to SecStaticCode
        var staticCode: SecStaticCode?
        status = SecCodeCopyStaticCode(code, [], &staticCode)
        
        guard status == errSecSuccess, let staticCode = staticCode else {
            print("Failed to get SecStaticCode: \(status)")
            return nil
        }
        
        var signingInfo: CFDictionary?
        status = SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &signingInfo)
        
        guard status == errSecSuccess, let info = signingInfo as? [String: Any] else {
            print("Failed to get signing information: \(status)")
            return nil
        }
        
        // Extract code directory hash (cdhash)
        if let cdhash = info[kSecCodeInfoUnique as String] as? Data {
            return cdhash.map { String(format: "%02x", $0) }.joined()
        }
        
        return nil
    }
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Querying user TCC database..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.model.queryTCCDatabase()
            
            DispatchQueue.main.async {
                self.entries = result.entries
                self.isLoading = false
                
                if let error = result.error {
                    self.errorMessage = error
                }
                
                if result.entries.isEmpty {
                    self.statusMessage = "No user TCC entries found"
                } else {
                    let withTeamID = result.entries.filter { $0.parsedTeamID != nil }.count
                    let withCSReq = result.entries.filter { $0.csreq != nil }.count
                    self.statusMessage = "Loaded \(result.entries.count) user TCC entries (\(withCSReq) with csreq, \(withTeamID) with Team ID)"
                }
            }
        }
    }
    
    func revokeAndBlacklistPermission(entry: UserEntry, reason: String? = nil, completion: @escaping (Bool, String) -> Void) {
        userService.revokeAndBlacklistPermission(
            service: entry.service,
            client: entry.client,
            bundleID: entry.parsedBundleID,
            teamID: entry.parsedTeamID,
            reason: reason
        ) { [weak self] success, message in
            if success {
                self?.loadTCCData()
            }
            completion(success, message)
        }
    }
}
