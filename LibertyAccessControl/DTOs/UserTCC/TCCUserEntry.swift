//
//  TCCUserEntry.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation

struct TCCUserEntry: Identifiable, Equatable {
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
    
    static func == (lhs: TCCUserEntry, rhs: TCCUserEntry) -> Bool {
        lhs.id == rhs.id
    }
    
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
