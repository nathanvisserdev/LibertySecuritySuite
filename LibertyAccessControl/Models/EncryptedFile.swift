//
//  EncryptedFile.swift
//  LibertyAccessControl
//
//  Created on 2025-12-12.
//

import Foundation

struct EncryptedFile: Identifiable, Codable {
    let id: UUID
    let originalFileName: String
    let encryptedFilePath: String
    let encryptionDate: Date
    let fileSize: Int64
    let algorithm: String // "AES-256-GCM"
    
    init(
        id: UUID = UUID(),
        originalFileName: String,
        encryptedFilePath: String,
        encryptionDate: Date = Date(),
        fileSize: Int64,
        algorithm: String = "AES-256-GCM"
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

struct EncryptionMetadata: Codable {
    let originalFileName: String
    let encryptionDate: Date
    let algorithm: String
    let salt: Data
    let iv: Data
    
    func toJSON() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    static func fromJSON(_ data: Data) -> EncryptionMetadata? {
        return try? JSONDecoder().decode(EncryptionMetadata.self, from: data)
    }
}
