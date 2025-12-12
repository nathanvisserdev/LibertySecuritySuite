//
//  FileEncryptionViewModel.swift
//  LibertyAccessControl
//
//  Created on 2025-12-12.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

@MainActor
class FileEncryptionViewModel: ObservableObject {
    @Published var encryptedFiles: [EncryptedFile] = []
    @Published var selectedFile: EncryptedFile?
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentOperation: String = ""
    
    // Encryption state
    @Published var showEncryptionDialog = false
    @Published var encryptionPassword = ""
    @Published var encryptionPasswordConfirm = ""
    @Published var selectedFileToEncrypt: URL?
    
    // Decryption state
    @Published var showDecryptionDialog = false
    @Published var decryptionPassword = ""
    @Published var fileToDecrypt: EncryptedFile?
    
    // Alerts
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showDeleteConfirmation = false
    @Published var fileToDelete: EncryptedFile?
    
    private let service = FileEncryptionService.shared
    
    init() {
        loadEncryptedFiles()
        setupObservers()
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        Task { @MainActor in
            for await isProcessing in service.$isProcessing.values {
                self.isProcessing = isProcessing
            }
        }
        
        Task { @MainActor in
            for await progress in service.$progress.values {
                self.progress = progress
            }
        }
        
        Task { @MainActor in
            for await operation in service.$currentOperation.values {
                self.currentOperation = operation
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadEncryptedFiles() {
        encryptedFiles = service.getEncryptionHistory()
    }
    
    // MARK: - Encryption
    
    func selectFileToEncrypt() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select a file to encrypt"
        
        panel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = panel.url {
                self.selectedFileToEncrypt = url
                self.encryptionPassword = ""
                self.encryptionPasswordConfirm = ""
                self.showEncryptionDialog = true
            }
        }
    }
    
    func performEncryption() {
        guard let fileURL = selectedFileToEncrypt else { return }
        
        // Validate password
        guard service.validatePassword(encryptionPassword) else {
            showError(title: "Invalid Password", message: "Password must be at least 8 characters long.")
            return
        }
        
        // Check passwords match
        guard encryptionPassword == encryptionPasswordConfirm else {
            showError(title: "Password Mismatch", message: "Passwords do not match.")
            return
        }
        
        showEncryptionDialog = false
        
        Task {
            do {
                let encryptedURL = try await service.encryptFile(at: fileURL, password: encryptionPassword)
                
                // Clear sensitive data
                encryptionPassword = ""
                encryptionPasswordConfirm = ""
                selectedFileToEncrypt = nil
                
                // Reload files
                loadEncryptedFiles()
                
                showSuccess(
                    title: "Encryption Successful",
                    message: "File encrypted and saved to:\n\(encryptedURL.path)"
                )
            } catch {
                showError(title: "Encryption Failed", message: error.localizedDescription)
            }
        }
    }
    
    func cancelEncryption() {
        showEncryptionDialog = false
        encryptionPassword = ""
        encryptionPasswordConfirm = ""
        selectedFileToEncrypt = nil
    }
    
    // MARK: - Decryption
    
    func initiateDecryption(file: EncryptedFile) {
        fileToDecrypt = file
        decryptionPassword = ""
        showDecryptionDialog = true
    }
    
    func performDecryption() {
        guard let file = fileToDecrypt else { return }
        
        // Validate password
        guard !decryptionPassword.isEmpty else {
            showError(title: "Invalid Password", message: "Please enter the decryption password.")
            return
        }
        
        showDecryptionDialog = false
        
        Task {
            do {
                let encryptedURL = URL(fileURLWithPath: file.encryptedFilePath)
                let decryptedURL = try await service.decryptFile(
                    at: encryptedURL,
                    password: decryptionPassword
                )
                
                // Clear sensitive data
                decryptionPassword = ""
                fileToDecrypt = nil
                
                showSuccess(
                    title: "Decryption Successful",
                    message: "File decrypted and saved to:\n\(decryptedURL.path)"
                )
            } catch {
                showError(title: "Decryption Failed", message: error.localizedDescription)
            }
        }
    }
    
    func cancelDecryption() {
        showDecryptionDialog = false
        decryptionPassword = ""
        fileToDecrypt = nil
    }
    
    // MARK: - File Management
    
    func selectFile(_ file: EncryptedFile) {
        selectedFile = file
    }
    
    func confirmDeleteFile(_ file: EncryptedFile) {
        fileToDelete = file
        showDeleteConfirmation = true
    }
    
    func deleteFile() {
        guard let file = fileToDelete else { return }
        
        if service.deleteEncryptedFile(file) {
            loadEncryptedFiles()
            
            if selectedFile?.id == file.id {
                selectedFile = nil
            }
        }
        
        fileToDelete = nil
        showDeleteConfirmation = false
    }
    
    func exportEncryptedFile(_ file: EncryptedFile) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.originalFileName.replacingOccurrences(of: ".", with: "_") + ".encrypted"
        panel.message = "Export encrypted file"
        panel.allowedContentTypes = [UTType.data]
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                let sourceURL = URL(fileURLWithPath: file.encryptedFilePath)
                try FileManager.default.copyItem(at: sourceURL, to: url)
                
                self?.showSuccess(
                    title: "Export Successful",
                    message: "Encrypted file exported to:\n\(url.path)"
                )
            } catch {
                self?.showError(title: "Export Failed", message: error.localizedDescription)
            }
        }
    }
    
    func importEncryptedFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select an encrypted file to import"
        panel.allowedContentTypes = [UTType.data]
        
        panel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = panel.url {
                self.fileToDecrypt = EncryptedFile(
                    originalFileName: url.deletingPathExtension().lastPathComponent,
                    encryptedFilePath: url.path,
                    fileSize: 0,
                    algorithm: "AES-256-GCM"
                )
                self.decryptionPassword = ""
                self.showDecryptionDialog = true
            }
        }
    }
    
    // MARK: - Password Validation
    
    var passwordStrength: PasswordStrength {
        service.getPasswordStrength(encryptionPassword)
    }
    
    var passwordsMatch: Bool {
        !encryptionPassword.isEmpty && encryptionPassword == encryptionPasswordConfirm
    }
    
    var canEncrypt: Bool {
        service.validatePassword(encryptionPassword) && passwordsMatch
    }
    
    // MARK: - Alerts
    
    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
