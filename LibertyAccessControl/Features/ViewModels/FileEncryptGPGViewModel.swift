//
//  FileEncryptGPGViewModel.swift
//  LibertyAccessControl
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class FileEncryptGPGViewModel: ObservableObject {
    @Published var savedKeys: [GPGPublicKey] = []
    @Published var selectedKeyId: UUID?
    @Published var pastedKey: String = ""
    @Published var keyName: String = ""
    @Published var showNamePrompt: Bool = false

    @Published var selectedFileURL: URL?

    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentOperation: String = ""

    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private let service = FileEncryptGPGService.shared

    init() {
        loadSavedKeys()
    }

    func loadSavedKeys() {
        savedKeys = service.getSavedPublicKeys()
    }

    func savePastedKey(as name: String) {
        let trimmed = pastedKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showError(title: "No Key", message: "Paste a public key before saving.")
            return
        }

        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Imported Key" : name
        let newKey = service.savePublicKey(name: finalName, keyASCII: trimmed)
        loadSavedKeys()
        selectedKeyId = newKey.id
        // clear name field after save
        keyName = ""
    }

    /// Called by the view when user taps Save; will prompt for a name if none provided
    func requestSavePastedKey() {
        let trimmed = pastedKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showError(title: "No Key", message: "Paste a public key before saving.")
            return
        }

        if keyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // ask user for a name
            showNamePrompt = true
        } else {
            savePastedKey(as: keyName)
        }
    }

    func confirmSavePastedKey(withName name: String) {
        savePastedKey(as: name)
        showNamePrompt = false
    }

    func importKeyFromFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.data, UTType.text]
        panel.message = "Select an ASCII-armored public key file to import"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else { return }

            if let data = try? Data(contentsOf: url), let s = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.pastedKey = s
                    // Suggest a name from the file name (without extension)
                    let suggested = url.deletingPathExtension().lastPathComponent
                    self.keyName = suggested
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(title: "Import Failed", message: "Unable to read selected key file.")
                }
            }
        }
    }

    func deleteKey(_ key: GPGPublicKey) {
        service.deletePublicKey(key)
        loadSavedKeys()
    }

    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select a file to encrypt with GPG"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.selectedFileURL = url
        }
    }

    func encryptUsingSelectedKey() {
        guard let fileURL = selectedFileURL else { return }
        Task {
            do {
                isProcessing = true
                if let keyId = selectedKeyId {
                    let out = try await service.encryptFile(at: fileURL, usingPublicKeyId: keyId)
                    showSuccess(title: "Encrypted", message: "Saved to: \(out.path)")
                } else if !pastedKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let out = try await service.encryptFile(at: fileURL, publicKeyASCII: pastedKey)
                    showSuccess(title: "Encrypted", message: "Saved to: \(out.path)")
                } else {
                    showError(title: "No Key", message: "Please select a saved key or paste a public key to use for encryption.")
                }
            } catch {
                showError(title: "Encryption Failed", message: error.localizedDescription)
            }
            isProcessing = false
        }
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
