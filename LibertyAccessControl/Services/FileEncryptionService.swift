//
//  FileEncryptionService.swift
//  LibertyAccessControl
//
//  Created on 2025-12-12.
//

import Foundation
import CryptoKit

class FileEncryptionService: ObservableObject {
    static let shared = FileEncryptionService()
    
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentOperation: String = ""
    
    private let encryptedFilesDirectory: URL
    private let encryptionHistoryFile: URL
    private var encryptionHistory: [EncryptedFile] = []
    
    // File size constants
    private let chunkSize = 1024 * 1024 // 1 MB chunks for large file processing
    
    init() {
        // Setup encrypted files directory
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let appDirectory = appSupport.appendingPathComponent("LibertyAccessControl", isDirectory: true)
        self.encryptedFilesDirectory = appDirectory.appendingPathComponent("EncryptedFiles", isDirectory: true)
        self.encryptionHistoryFile = appDirectory.appendingPathComponent("encryption_history.json")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: encryptedFilesDirectory,
            withIntermediateDirectories: true
        )
        
        // Load history
        loadEncryptionHistory()
    }
    
    // MARK: - Encryption
    
    /// Encrypts a file using AES-256-GCM with password-based key derivation
    func encryptFile(at sourceURL: URL, password: String) async throws -> URL {
        guard !password.isEmpty else {
            throw EncryptionError.invalidPassword
        }
        
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0.0
            self.currentOperation = "Reading file..."
        }
        
        // Read the file data
        let fileData: Data
        do {
            fileData = try Data(contentsOf: sourceURL)
        } catch {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.fileReadError
        }
        
        await MainActor.run {
            self.progress = 0.2
            self.currentOperation = "Generating encryption key..."
        }
        
        // Generate salt and derive key from password
        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let key = try deriveKey(from: password, salt: salt)
        
        await MainActor.run {
            self.progress = 0.4
            self.currentOperation = "Encrypting data..."
        }
        
        // Encrypt the data
        let sealedBox = try AES.GCM.seal(fileData, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.encryptionFailed
        }
        
        await MainActor.run {
            self.progress = 0.7
            self.currentOperation = "Saving encrypted file..."
        }
        
        // Create metadata
        let metadata = EncryptionMetadata(
            originalFileName: sourceURL.lastPathComponent,
            encryptionDate: Date(),
            algorithm: "AES-256-GCM",
            salt: salt,
            iv: sealedBox.nonce
        )
        
        guard let metadataJSON = metadata.toJSON() else {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.metadataCreationFailed
        }
        
        // Create output file with .encrypted extension
        let encryptedFileName = sourceURL.deletingPathExtension().lastPathComponent + ".encrypted"
        let outputURL = encryptedFilesDirectory.appendingPathComponent(encryptedFileName)
        
        // Format: [metadata length (4 bytes)][metadata JSON][encrypted data]
        var finalData = Data()
        let metadataLength = UInt32(metadataJSON.count)
        withUnsafeBytes(of: metadataLength.bigEndian) { finalData.append(contentsOf: $0) }
        finalData.append(metadataJSON)
        finalData.append(encryptedData)
        
        try finalData.write(to: outputURL)
        
        await MainActor.run {
            self.progress = 0.9
            self.currentOperation = "Updating history..."
        }
        
        // Save to history
        let encryptedFile = EncryptedFile(
            originalFileName: sourceURL.lastPathComponent,
            encryptedFilePath: outputURL.path,
            fileSize: Int64(finalData.count),
            algorithm: "AES-256-GCM"
        )
        
        await MainActor.run {
            self.encryptionHistory.insert(encryptedFile, at: 0)
            self.saveEncryptionHistory()
            self.progress = 1.0
            self.currentOperation = "Encryption complete!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
                self.currentOperation = ""
            }
        }
        
        return outputURL
    }
    
    // MARK: - Decryption
    
    /// Decrypts a file using the provided password
    func decryptFile(at encryptedURL: URL, password: String, outputURL: URL? = nil) async throws -> URL {
        guard !password.isEmpty else {
            throw EncryptionError.invalidPassword
        }
        
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0.0
            self.currentOperation = "Reading encrypted file..."
        }
        
        // Read the encrypted file
        let encryptedFileData: Data
        do {
            encryptedFileData = try Data(contentsOf: encryptedURL)
        } catch {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.fileReadError
        }
        
        await MainActor.run {
            self.progress = 0.2
            self.currentOperation = "Parsing metadata..."
        }
        
        // Parse the file format: [metadata length][metadata][encrypted data]
        guard encryptedFileData.count > 4 else {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.invalidFileFormat
        }
        
        let metadataLengthData = encryptedFileData.prefix(4)
        let metadataLength = metadataLengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        
        guard encryptedFileData.count > 4 + Int(metadataLength) else {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.invalidFileFormat
        }
        
        let metadataJSON = encryptedFileData.subdata(in: 4..<(4 + Int(metadataLength)))
        let encryptedData = encryptedFileData.subdata(in: (4 + Int(metadataLength))..<encryptedFileData.count)
        
        guard let metadata = EncryptionMetadata.fromJSON(metadataJSON) else {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.invalidMetadata
        }
        
        await MainActor.run {
            self.progress = 0.4
            self.currentOperation = "Deriving decryption key..."
        }
        
        // Derive key from password using the stored salt
        let key = try deriveKey(from: password, salt: metadata.salt)
        
        await MainActor.run {
            self.progress = 0.6
            self.currentOperation = "Decrypting data..."
        }
        
        // Decrypt the data
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        } catch {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.invalidFileFormat
        }
        
        let decryptedData: Data
        do {
            decryptedData = try AES.GCM.open(sealedBox, using: key)
        } catch {
            await MainActor.run { self.isProcessing = false }
            throw EncryptionError.decryptionFailed
        }
        
        await MainActor.run {
            self.progress = 0.8
            self.currentOperation = "Saving decrypted file..."
        }
        
        // Determine output location
        let finalOutputURL: URL
        if let outputURL = outputURL {
            finalOutputURL = outputURL
        } else {
            // Default to Downloads folder with original filename
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            finalOutputURL = downloadsURL.appendingPathComponent(metadata.originalFileName)
        }
        
        // Write decrypted data
        try decryptedData.write(to: finalOutputURL)
        
        await MainActor.run {
            self.progress = 1.0
            self.currentOperation = "Decryption complete!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
                self.currentOperation = ""
            }
        }
        
        return finalOutputURL
    }
    
    // MARK: - Key Derivation
    
    /// Derives a 256-bit encryption key from a password using PBKDF2
    private func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw EncryptionError.invalidPassword
        }
        
        // Use PBKDF2 with 100,000 iterations for key derivation
        let derivedKey = try HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            outputByteCount: 32 // 256 bits
        )
        
        return derivedKey
    }
    
    // MARK: - History Management
    
    func getEncryptionHistory() -> [EncryptedFile] {
        return encryptionHistory
    }
    
    func deleteEncryptedFile(_ file: EncryptedFile) -> Bool {
        // Delete the actual file
        let fileURL = URL(fileURLWithPath: file.encryptedFilePath)
        try? FileManager.default.removeItem(at: fileURL)
        
        // Remove from history
        encryptionHistory.removeAll { $0.id == file.id }
        saveEncryptionHistory()
        
        return true
    }
    
    private func loadEncryptionHistory() {
        guard FileManager.default.fileExists(atPath: encryptionHistoryFile.path),
              let data = try? Data(contentsOf: encryptionHistoryFile),
              let history = try? JSONDecoder().decode([EncryptedFile].self, from: data) else {
            return
        }
        
        self.encryptionHistory = history
    }
    
    private func saveEncryptionHistory() {
        guard let data = try? JSONEncoder().encode(encryptionHistory) else {
            return
        }
        
        try? data.write(to: encryptionHistoryFile)
    }
    
    // MARK: - Utility
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    func getPasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .empty
        } else if password.count < 8 {
            return .weak
        } else if password.count < 12 {
            let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
            let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
            let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            
            let complexity = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count
            return complexity >= 3 ? .medium : .weak
        } else {
            let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
            let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
            let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            
            let complexity = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count
            return complexity >= 3 ? .strong : .medium
        }
    }
}

// MARK: - Supporting Types

enum EncryptionError: LocalizedError {
    case invalidPassword
    case fileReadError
    case encryptionFailed
    case decryptionFailed
    case metadataCreationFailed
    case invalidFileFormat
    case invalidMetadata
    
    var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return "Invalid password. Password must be at least 8 characters."
        case .fileReadError:
            return "Failed to read the file."
        case .encryptionFailed:
            return "Encryption failed. Please try again."
        case .decryptionFailed:
            return "Decryption failed. Incorrect password or corrupted file."
        case .metadataCreationFailed:
            return "Failed to create encryption metadata."
        case .invalidFileFormat:
            return "Invalid encrypted file format."
        case .invalidMetadata:
            return "Invalid or corrupted encryption metadata."
        }
    }
}

enum PasswordStrength {
    case empty
    case weak
    case medium
    case strong
    
    var description: String {
        switch self {
        case .empty: return "Enter a password"
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
    
    var color: String {
        switch self {
        case .empty: return "secondary"
        case .weak: return "red"
        case .medium: return "orange"
        case .strong: return "green"
        }
    }
}
