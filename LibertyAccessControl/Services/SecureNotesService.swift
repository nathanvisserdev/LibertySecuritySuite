//
//  SecureNotesService.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

/// Service for managing encrypted notes stored in the Keychain
class SecureNotesService {
    static let shared = SecureNotesService()
    
    private let keychainService = "com.liberty.LibertyAccessControl.secureNotes"
    private let notesKey = "encryptedNotes"
    private let encryptionKeyTag = "com.liberty.LibertyAccessControl.notesEncryptionKey"
    
    private init() {
        // Ensure encryption key exists
        _ = getOrCreateEncryptionKey()
    }
    
    // MARK: - Encryption Key Management
    
    /// Gets existing encryption key or creates a new one
    private func getOrCreateEncryptionKey() -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKey = loadEncryptionKeyFromKeychain() {
            return existingKey
        }
        
        // Create new key
        let newKey = SymmetricKey(size: .bits256)
        saveEncryptionKeyToKeychain(newKey)
        return newKey
    }
    
    private func loadEncryptionKeyFromKeychain() -> SymmetricKey? {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your encrypted notes"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveEncryptionKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Create access control for biometric authentication
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet, // Requires Touch ID/Face ID
            &accessControlError
        ) else {
            print("⚠️ Failed to create access control: \(accessControlError.debugDescription)")
            // Fall back to no biometric protection
            saveEncryptionKeyWithoutBiometrics(keyData)
            return
        }
        
        let context = LAContext()
        context.localizedReason = "Authenticate to access your encrypted notes"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessControl as String: accessControl,
            kSecUseAuthenticationContext as String: context
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item with biometric protection
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ Failed to save encryption key to Keychain with biometrics: \(status)")
            // Fall back to no biometric protection
            saveEncryptionKeyWithoutBiometrics(keyData)
        }
    }
    
    private func saveEncryptionKeyWithoutBiometrics(_ keyData: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // MARK: - Note Encryption/Decryption
    
    private func encrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Notes Management
    
    /// Load all notes from encrypted storage
    func loadNotes() -> [SecureNote] {
        guard let encryptedData = UserDefaults.standard.data(forKey: notesKey) else {
            return []
        }
        
        do {
            let decryptedData = try decrypt(encryptedData)
            let notes = try JSONDecoder().decode([SecureNote].self, from: decryptedData)
            return notes
        } catch {
            print("⚠️ Failed to load notes: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Save all notes to encrypted storage
    func saveNotes(_ notes: [SecureNote]) {
        do {
            let jsonData = try JSONEncoder().encode(notes)
            let encryptedData = try encrypt(jsonData)
            UserDefaults.standard.set(encryptedData, forKey: notesKey)
        } catch {
            print("⚠️ Failed to save notes: \(error.localizedDescription)")
        }
    }
    
    /// Create a new note
    func createNote() -> SecureNote {
        let note = SecureNote()
        var notes = loadNotes()
        notes.insert(note, at: 0) // Add to beginning
        saveNotes(notes)
        return note
    }
    
    /// Update an existing note
    func updateNote(_ updatedNote: SecureNote) {
        var notes = loadNotes()
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveNotes(notes)
        }
    }
    
    /// Delete a note
    func deleteNote(_ note: SecureNote) {
        var notes = loadNotes()
        notes.removeAll { $0.id == note.id }
        saveNotes(notes)
    }
    
    /// Delete multiple notes
    func deleteNotes(_ notesToDelete: Set<SecureNote.ID>) {
        var notes = loadNotes()
        notes.removeAll { notesToDelete.contains($0.id) }
        saveNotes(notes)
    }
    
    /// Search notes by content or title
    func searchNotes(query: String) -> [SecureNote] {
        let notes = loadNotes()
        let lowercaseQuery = query.lowercased()
        
        return notes.filter { note in
            note.title.lowercased().contains(lowercaseQuery) ||
            note.content.lowercased().contains(lowercaseQuery) ||
            note.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
}
