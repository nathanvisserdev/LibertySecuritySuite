//
//  GPGEncryptedFile.swift
//  LibertyAccessControl
//

import Foundation

struct GPGEncryptedFile: Identifiable, Codable, Hashable {
    let id: UUID
    let originalFileName: String
    let encryptedFilePath: String
    let encryptionDate: Date
    let fileSize: Int64
    let algorithm: String // e.g. "OpenPGP"

    init(
        id: UUID = UUID(),
        originalFileName: String,
        encryptedFilePath: String,
        encryptionDate: Date = Date(),
        fileSize: Int64,
        algorithm: String = "OpenPGP"
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.encryptedFilePath = encryptedFilePath
        self.encryptionDate = encryptionDate
        self.fileSize = fileSize
        self.algorithm = algorithm
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: encryptionDate)
    }
}
