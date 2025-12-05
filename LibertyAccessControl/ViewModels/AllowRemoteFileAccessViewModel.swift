//
//  AllowRemoteFileAccessViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import Darwin

class AllowRemoteFileAccessViewModel: ObservableObject {
    @Published var isAccessGranted: Bool = false
    @Published var statusMessage: String = "Remote file access not granted"
    @Published var errorMessage: String?
    
    private var serverSocket: Int32 = -1
    private var isRunning: Bool = false
    private let port: UInt16 = 9999
    private var acceptQueue: DispatchQueue?
    
    func grantAccess() {
        // DARWIN: Create socket using BSD socket() syscall - direct kernel call to create TCP socket
        serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        
        guard serverSocket >= 0 else {
            DispatchQueue.main.async { [weak self] in
                // DARWIN: strerror() syscall to get error description from errno
                self?.errorMessage = "Failed to create socket: \(String(cString: strerror(errno)))"
                self?.statusMessage = "Failed to grant access"
            }
            return
        }
        
        // DARWIN: setsockopt() syscall - configure socket to allow address reuse
        var reuseAddr: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))
        
        // DARWIN: Prepare sockaddr_in structure for IPv4 addressing
        var serverAddr = sockaddr_in()
        serverAddr.sin_family = sa_family_t(AF_INET)
        serverAddr.sin_port = port.bigEndian
        serverAddr.sin_addr.s_addr = INADDR_ANY.bigEndian
        serverAddr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        
        // DARWIN: bind() syscall - bind socket to port and address via XNU kernel
        let bindResult = withUnsafePointer(to: &serverAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                Darwin.bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard bindResult >= 0 else {
            // DARWIN: close() syscall - close socket file descriptor
            close(serverSocket)
            serverSocket = -1
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to bind socket: \(String(cString: strerror(errno)))"
                self?.statusMessage = "Failed to grant access"
            }
            return
        }
        
        // DARWIN: listen() syscall - mark socket as passive, ready to accept connections
        let listenResult = listen(serverSocket, 5)
        
        guard listenResult >= 0 else {
            close(serverSocket)
            serverSocket = -1
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to listen: \(String(cString: strerror(errno)))"
                self?.statusMessage = "Failed to grant access"
            }
            return
        }
        
        // Update UI
        DispatchQueue.main.async { [weak self] in
            self?.isAccessGranted = true
            self?.statusMessage = "Remote file access granted on port \(self?.port ?? 0)"
            self?.errorMessage = nil
        }
        
        // Start accepting connections
        isRunning = true
        acceptQueue = DispatchQueue(label: "com.libertyaccess.accept", qos: .userInitiated)
        acceptQueue?.async { [weak self] in
            self?.acceptConnections()
        }
    }
    
    func revokeAccess() {
        isRunning = false
        
        if serverSocket >= 0 {
            // DARWIN: shutdown() syscall - gracefully close both read/write on socket
            Darwin.shutdown(serverSocket, SHUT_RDWR)
            // DARWIN: close() syscall - release socket file descriptor
            close(serverSocket)
            serverSocket = -1
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isAccessGranted = false
            self?.statusMessage = "Remote file access revoked"
            self?.errorMessage = nil
        }
    }
    
    private func acceptConnections() {
        while isRunning && serverSocket >= 0 {
            var clientAddr = sockaddr_in()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            // DARWIN: accept() syscall - blocks until client connects, returns new socket FD
            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    Darwin.accept(serverSocket, sockaddrPtr, &clientAddrLen)
                }
            }
            
            guard clientSocket >= 0 else {
                if isRunning {
                    print("Accept error: \(String(cString: strerror(errno)))")
                }
                continue
            }
            
            // Handle client connection in separate queue
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.handleClient(clientSocket: clientSocket)
            }
        }
    }
    
    private func handleClient(clientSocket: Int32) {
        defer {
            // DARWIN: close() syscall - close client socket when done
            close(clientSocket)
        }
        
        var buffer = [UInt8](repeating: 0, count: 4096)
        
        // DARWIN: recv() syscall - read data from socket into buffer
        let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)
        
        guard bytesRead > 0 else {
            return
        }
        
        guard let request = String(bytes: buffer[0..<bytesRead], encoding: .utf8) else {
            sendResponse("ERROR: Invalid UTF-8", to: clientSocket)
            return
        }
        
        processFileRequest(request.trimmingCharacters(in: .whitespacesAndNewlines), clientSocket: clientSocket)
    }
    
    private func processFileRequest(_ request: String, clientSocket: Int32) {
        let components = request.split(separator: ":", maxSplits: 1)
        
        guard components.count == 2 else {
            sendResponse("ERROR: Invalid request format. Use READ:/path or LIST:/path", to: clientSocket)
            return
        }
        
        let command = String(components[0])
        let path = String(components[1])
        
        switch command {
        case "READ":
            readFile(at: path, clientSocket: clientSocket)
        case "LIST":
            listDirectory(at: path, clientSocket: clientSocket)
        case "WRITE":
            sendResponse("ERROR: Write operations not implemented", to: clientSocket)
        default:
            sendResponse("ERROR: Unknown command '\(command)'", to: clientSocket)
        }
    }
    
    private func readFile(at path: String, clientSocket: Int32) {
        // DARWIN: open() syscall - open file and get file descriptor
        let fd = open(path, O_RDONLY)
        
        guard fd >= 0 else {
            // DARWIN: strerror() to get error message from errno
            let error = String(cString: strerror(errno))
            sendResponse("ERROR: Failed to open file: \(error)", to: clientSocket)
            return
        }
        
        defer {
            // DARWIN: close() syscall - close file descriptor
            close(fd)
        }
        
        // DARWIN: fstat() syscall - get file metadata including size
        var fileStat = stat()
        guard fstat(fd, &fileStat) == 0 else {
            sendResponse("ERROR: Failed to stat file", to: clientSocket)
            return
        }
        
        let fileSize = Int(fileStat.st_size)
        var buffer = [UInt8](repeating: 0, count: fileSize)
        
        // DARWIN: read() syscall - read file contents into buffer
        let bytesRead = read(fd, &buffer, fileSize)
        
        guard bytesRead > 0 else {
            sendResponse("ERROR: Failed to read file", to: clientSocket)
            return
        }
        
        if let content = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
            sendResponse("SUCCESS:\n\(content)", to: clientSocket)
        } else {
            sendResponse("SUCCESS: [Binary file, \(bytesRead) bytes]", to: clientSocket)
        }
    }
    
    private func listDirectory(at path: String, clientSocket: Int32) {
        // DARWIN: opendir() syscall - open directory stream for reading
        guard let dir = opendir(path) else {
            let error = String(cString: strerror(errno))
            sendResponse("ERROR: Failed to open directory: \(error)", to: clientSocket)
            return
        }
        
        defer {
            // DARWIN: closedir() syscall - close directory stream
            closedir(dir)
        }
        
        var entries: [String] = []
        
        // DARWIN: readdir() syscall - read next directory entry
        while let entry = readdir(dir) {
            var nameTuple = entry.pointee.d_name
            let name = withUnsafePointer(to: &nameTuple) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen) + 1) {
                    String(cString: $0)
                }
            }
            
            // Skip . and ..
            if name != "." && name != ".." {
                entries.append(name)
            }
        }
        
        let listing = entries.joined(separator: "\n")
        sendResponse("SUCCESS:\n\(listing)", to: clientSocket)
    }
    
    private func sendResponse(_ response: String, to clientSocket: Int32) {
        var bytes = Array(response.utf8)
        // DARWIN: send() syscall - write data to socket
        _ = send(clientSocket, &bytes, bytes.count, 0)
    }
    
    deinit {
        revokeAccess()
    }
}
