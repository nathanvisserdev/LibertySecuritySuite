//
//  TCCUserViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import SQLite3

struct TCCUserEntry: Identifiable {
    let id = UUID()
    let service: String
    let client: String
    let client_type: Int
    let auth_value: Int
    let auth_reason: Int
    let auth_version: Int
    let csreq: Data?
    let policy_id: Int?
    let indirect_object_identifier_type: Int?
    let indirect_object_identifier: String
    let indirect_object_code_identity: Data?
    let flags: Int?
    let last_modified: Date?
    let pid: Int?
    let pid_version: Int?
    let boot_uuid: String
    let last_reminded: Date?
    
    // Computed properties for parsed CSReq data
    var parsedBundleID: String? {
        guard let csreq = csreq else { return nil }
        return Self.parseCSReqBundleID(from: csreq)
    }
    
    var parsedTeamID: String? {
        guard let csreq = csreq else { return nil }
        return Self.parseCSReqTeamID(from: csreq)
    }
    
    // Parse bundle identifier from CSReq blob
    private static func parseCSReqBundleID(from data: Data) -> String? {
        guard data.count >= 8 else { return nil }
        
        var offset = 8
        
        while offset + 8 < data.count {
            let op = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }.bigEndian
            
            if op == 0x00000002 {
                offset += 4
                let length = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }.bigEndian)
                offset += 4
                
                if offset + length <= data.count {
                    let stringData = data.subdata(in: offset..<(offset + length))
                    if let bundleID = String(data: stringData, encoding: .utf8) {
                        return bundleID
                    }
                }
                break
            }
            offset += 4
        }
        
        return nil
    }
    
    // Parse Team ID from CSReq blob
    private static func parseCSReqTeamID(from data: Data) -> String? {
        guard data.count >= 8 else { return nil }
        
        let hexString = data.map { String(format: "%02X", $0) }.joined()
        
        if let range = hexString.range(of: "7375626A6563742E4F55") {
            let startIndex = hexString.distance(from: hexString.startIndex, to: range.upperBound)
            
            var searchIndex = startIndex
            while searchIndex + 16 < hexString.count {
                let chunk = String(hexString[hexString.index(hexString.startIndex, offsetBy: searchIndex)..<hexString.index(hexString.startIndex, offsetBy: searchIndex + 8)])
                
                if chunk == "00000001" {
                    let lengthStart = searchIndex + 8
                    if lengthStart + 8 <= hexString.count {
                        let lengthHex = String(hexString[hexString.index(hexString.startIndex, offsetBy: lengthStart)..<hexString.index(hexString.startIndex, offsetBy: lengthStart + 8)])
                        
                        if let length = UInt32(lengthHex, radix: 16) {
                            let teamIDStart = lengthStart + 8
                            let teamIDEnd = teamIDStart + Int(length) * 2
                            
                            if teamIDEnd <= hexString.count {
                                let teamIDHex = String(hexString[hexString.index(hexString.startIndex, offsetBy: teamIDStart)..<hexString.index(hexString.startIndex, offsetBy: teamIDEnd)])
                                
                                var teamIDBytes = [UInt8]()
                                var index = teamIDHex.startIndex
                                while index < teamIDHex.endIndex {
                                    let nextIndex = teamIDHex.index(index, offsetBy: 2)
                                    if let byte = UInt8(teamIDHex[index..<nextIndex], radix: 16) {
                                        teamIDBytes.append(byte)
                                    }
                                    index = nextIndex
                                }
                                
                                if let teamID = String(bytes: teamIDBytes, encoding: .utf8) {
                                    return teamID.trimmingCharacters(in: .controlCharacters.union(.whitespaces))
                                }
                            }
                        }
                    }
                    break
                }
                searchIndex += 8
            }
        }
        
        return nil
    }
}

class TCCUserViewModel: ObservableObject {
    @Published var statusMessage: String = "User TCC Database - Ready to query"
    @Published var errorMessage: String?
    @Published var entries: [TCCUserEntry] = []
    @Published var isLoading: Bool = false
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Querying user TCC database..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let results = self?.queryTCCDatabaseViaScript() ?? []
            
            DispatchQueue.main.async {
                self?.entries = results
                self?.isLoading = false
                if results.isEmpty {
                    self?.statusMessage = "No user TCC entries found"
                } else {
                    let withTeamID = results.filter { $0.parsedTeamID != nil }.count
                    let withCSReq = results.filter { $0.csreq != nil }.count
                    self?.statusMessage = "Loaded \(results.count) user TCC entries (\(withCSReq) with csreq, \(withTeamID) with Team ID)"
                }
            }
        }
    }
    
    private func queryTCCDatabaseViaScript() -> [TCCUserEntry] {
        // Try to get script from app bundle, fall back to development path
        let scriptPath: String
        if let bundlePath = Bundle.main.path(forResource: "query_tcc", ofType: "sh") {
            scriptPath = bundlePath
        } else {
            scriptPath = "/Users/nathanvisser/Code/test/LibertyAccessControl/query_tcc.sh"
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: scriptPath)
        task.arguments = ["user"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            return parseScriptOutput(output)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to run query script: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    private func parseScriptOutput(_ output: String) -> [TCCUserEntry] {
        var entries: [TCCUserEntry] = []
        
        let lines = output.split(separator: "\n")
        for line in lines {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            
            guard fields.count >= 17 else { continue }
            
            let service = fields[0]
            let client = fields[1]
            let client_type = Int(fields[2]) ?? 0
            let auth_value = Int(fields[3]) ?? 0
            let auth_reason = Int(fields[4]) ?? 0
            let auth_version = Int(fields[5]) ?? 0
            
            let csreq: Data? = fields[6].isEmpty ? nil : Data(hex: fields[6])
            let policy_id: Int? = fields[7].isEmpty ? nil : Int(fields[7])
            let indirect_object_identifier_type: Int? = fields[8].isEmpty ? nil : Int(fields[8])
            let indirect_object_identifier = fields[9]
            let indirect_object_code_identity: Data? = fields[10].isEmpty ? nil : Data(hex: fields[10])
            let flags: Int? = fields[11].isEmpty ? nil : Int(fields[11])
            let last_modified: Date? = Int64(fields[12]).flatMap { $0 > 0 ? Date(timeIntervalSince1970: TimeInterval($0)) : nil }
            let pid: Int? = fields[13].isEmpty ? nil : Int(fields[13])
            let pid_version: Int? = fields[14].isEmpty ? nil : Int(fields[14])
            let boot_uuid = fields[15]
            let last_reminded: Date? = Int64(fields[16]).flatMap { $0 > 0 ? Date(timeIntervalSince1970: TimeInterval($0)) : nil }
            
            let entry = TCCUserEntry(
                service: service,
                client: client,
                client_type: client_type,
                auth_value: auth_value,
                auth_reason: auth_reason,
                auth_version: auth_version,
                csreq: csreq,
                policy_id: policy_id,
                indirect_object_identifier_type: indirect_object_identifier_type,
                indirect_object_identifier: indirect_object_identifier,
                indirect_object_code_identity: indirect_object_code_identity,
                flags: flags,
                last_modified: last_modified,
                pid: pid,
                pid_version: pid_version,
                boot_uuid: boot_uuid,
                last_reminded: last_reminded
            )
            entries.append(entry)
        }
        
        return entries
    }
}

// Extension to convert hex string to Data
extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}
