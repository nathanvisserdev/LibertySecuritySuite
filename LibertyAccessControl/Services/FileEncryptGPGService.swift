//
//  FileEncryptGPGService.swift
//  LibertyAccessControl
//

import Foundation
import Combine

final class FileEncryptGPGService: ObservableObject {
    static let shared = FileEncryptGPGService()

    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentOperation: String = ""

    private let encryptedFilesDirectory: URL
    private let publicKeysFile: URL
    private var publicKeys: [GPGPublicKey] = []
    private let encryptionHistoryFile: URL
    private var encryptionHistory: [GPGEncryptedFile] = []

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("LibertyAccessControl", isDirectory: true)
        self.encryptedFilesDirectory = appDirectory.appendingPathComponent("GPGEncryptedFiles", isDirectory: true)
        self.publicKeysFile = appDirectory.appendingPathComponent("gpg_keys.json")
        self.encryptionHistoryFile = appDirectory.appendingPathComponent("gpg_encryption_history.json")

        try? FileManager.default.createDirectory(at: encryptedFilesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        loadPublicKeys()
        loadEncryptionHistory()
    }

    // MARK: - Public Key Storage

    func getSavedPublicKeys() -> [GPGPublicKey] { publicKeys }

    func savePublicKey(name: String, keyASCII: String) -> GPGPublicKey {
        let key = GPGPublicKey(name: name, keyASCII: keyASCII)
        publicKeys.insert(key, at: 0)
        savePublicKeysToDisk()
        return key
    }

    func deletePublicKey(_ key: GPGPublicKey) {
        publicKeys.removeAll { $0.id == key.id }
        savePublicKeysToDisk()
    }

    private func loadPublicKeys() {
        guard FileManager.default.fileExists(atPath: publicKeysFile.path),
              let data = try? Data(contentsOf: publicKeysFile),
              let keys = try? JSONDecoder().decode([GPGPublicKey].self, from: data) else { return }
        self.publicKeys = keys
    }

    private func savePublicKeysToDisk() {
        guard let data = try? JSONEncoder().encode(publicKeys) else { return }
        try? data.write(to: publicKeysFile)
    }

    // MARK: - Encryption

    /// Encrypt using a saved key id
    func encryptFile(at sourceURL: URL, usingPublicKeyId keyId: UUID) async throws -> URL {
        guard let key = publicKeys.first(where: { $0.id == keyId }) else {
            throw GPGError.invalidPublicKey
        }
        return try await encryptFile(at: sourceURL, publicKeyASCII: key.keyASCII)
    }

    /// Encrypt using the provided ASCII-armored public key (pasted or temporary)
    func encryptFile(at sourceURL: URL, publicKeyASCII: String) async throws -> URL {
        guard !publicKeyASCII.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GPGError.invalidPublicKey
        }

        await MainActor.run { self.isProcessing = true; self.progress = 0.0; self.currentOperation = "Preparing GPG environment..." }

        // Create a temporary directory for GNUPGHOME and key file
        let tmpBase = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let gnupgHome = tmpBase.appendingPathComponent("gnupg", isDirectory: true)
        try FileManager.default.createDirectory(at: gnupgHome, withIntermediateDirectories: true)

        let keyFile = tmpBase.appendingPathComponent("publickey.asc")
        try publicKeyASCII.data(using: .utf8)?.write(to: keyFile)

        await MainActor.run { self.progress = 0.1; self.currentOperation = "Importing public key..." }

        let env = ["GNUPGHOME": gnupgHome.path]
        try runProcess("gpg", arguments: ["--batch", "--import", keyFile.path], environment: env)

        await MainActor.run { self.progress = 0.25; self.currentOperation = "Locating imported key..." }

        let keysOutput = try runProcess("gpg", arguments: ["--with-colons", "--list-keys"], environment: env)
        guard let fingerprint = parseFirstFingerprint(from: keysOutput) else {
            try? FileManager.default.removeItem(at: tmpBase)
            throw GPGError.noFingerprintFound
        }

        await MainActor.run { self.progress = 0.5; self.currentOperation = "Encrypting file..." }

        let encryptedFileName = sourceURL.deletingPathExtension().lastPathComponent + ".gpg"
        let outputURL = encryptedFilesDirectory.appendingPathComponent(encryptedFileName)

        try runProcess("gpg", arguments: ["--batch", "--yes", "--trust-model", "always", "--output", outputURL.path, "--encrypt", "--recipient", fingerprint, sourceURL.path], environment: env)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0
        let gpgFile = GPGEncryptedFile(originalFileName: sourceURL.lastPathComponent, encryptedFilePath: outputURL.path, fileSize: fileSize)

        await MainActor.run {
            self.encryptionHistory.insert(gpgFile, at: 0)
            self.saveEncryptionHistory()
            self.progress = 1.0
            self.currentOperation = "Encryption complete"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
                self.currentOperation = ""
            }
        }

        try? FileManager.default.removeItem(at: tmpBase)
        return outputURL
    }

    // MARK: - History

    func getEncryptionHistory() -> [GPGEncryptedFile] { encryptionHistory }

    func deleteEncryptedFile(_ file: GPGEncryptedFile) -> Bool {
        let fileURL = URL(fileURLWithPath: file.encryptedFilePath)
        try? FileManager.default.removeItem(at: fileURL)
        encryptionHistory.removeAll { $0.id == file.id }
        saveEncryptionHistory()
        return true
    }

    private func loadEncryptionHistory() {
        guard FileManager.default.fileExists(atPath: encryptionHistoryFile.path),
              let data = try? Data(contentsOf: encryptionHistoryFile),
              let history = try? JSONDecoder().decode([GPGEncryptedFile].self, from: data) else { return }
        self.encryptionHistory = history
    }

    private func saveEncryptionHistory() {
        guard let data = try? JSONEncoder().encode(encryptionHistory) else { return }
        try? data.write(to: encryptionHistoryFile)
    }

    // MARK: - Process Helpers

    private func parseFirstFingerprint(from gpgColonOutput: String) -> String? {
        let lines = gpgColonOutput.split(separator: "\n")
        for line in lines {
            let parts = line.split(separator: ":")
            if parts.count > 9 && parts[0] == "fpr" {
                return String(parts[9])
            }
        }
        return nil
    }

    private func runProcess(_ launchPath: String, arguments: [String], environment: [String: String]? = nil) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: which(launchPath) ?? launchPath)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        if let environment = environment { for (k, v) in environment { env[k] = v } }
        process.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw GPGError.processFailed(stdout: stdout, stderr: stderr, code: Int(process.terminationStatus))
        }

        return stdout + (stderr.isEmpty ? "" : "\n" + stderr)
    }

    private func which(_ cmd: String) -> String? {
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        which.arguments = [cmd]
        let pipe = Pipe()
        which.standardOutput = pipe
        try? which.run()
        which.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let s = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }
        return nil
    }
}

enum GPGError: LocalizedError {
    case invalidPublicKey
    case noFingerprintFound
    case processFailed(stdout: String, stderr: String, code: Int)

    var errorDescription: String? {
        switch self {
        case .invalidPublicKey: return "Invalid or empty public key provided."
        case .noFingerprintFound: return "Failed to determine key fingerprint after import."
        case let .processFailed(stdout, stderr, code):
            return "GPG failed (code \(code)). stdout: \(stdout) stderr: \(stderr)"
        }
    }
}
