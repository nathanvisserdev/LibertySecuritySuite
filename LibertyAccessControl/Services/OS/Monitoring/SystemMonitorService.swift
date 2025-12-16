//
//  SystemMonitorService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Darwin

class SystemMonitorService {
    private let parser: TCCLogParser
    private let notificationService: NotificationService
    
    private var monitoringQueue: DispatchQueue?
    private var isMonitoring: Bool = false
    private var logFileDescriptor: Int32 = -1
    
    var onRequestReceived: ((TCCAccessRequest) -> Void)?
    var onStatusChange: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    init(parser: TCCLogParser, notificationService: NotificationService) {
        self.parser = parser
        self.notificationService = notificationService
    }
    
    func startMonitoring() {
        isMonitoring = true
        onStatusChange?("TCC monitoring enabled - watching for access requests")
        
        monitoringQueue = DispatchQueue(label: "com.libertyaccess.tcc", qos: .userInitiated)
        monitoringQueue?.async { [weak self] in
            self?.monitorTCCDaemon()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        onStatusChange?("TCC monitoring disabled")
        
        if logFileDescriptor >= 0 {
            close(logFileDescriptor)
            logFileDescriptor = -1
        }
    }
    
    private func monitorTCCDaemon() {
        // Use 'log stream' command to monitor TCC daemon in real-time
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        task.arguments = [
            "stream",
            "--predicate", "subsystem == 'com.apple.TCC'",
            "--style", "compact"
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let handle = pipe.fileHandleForReading
            
            // Read output continuously
            while isMonitoring && task.isRunning {
                let data = handle.availableData
                
                guard !data.isEmpty else {
                    continue
                }
                
                if let output = String(data: data, encoding: .utf8) {
                    processTCCLogOutput(output)
                }
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onError?("Failed to start TCC monitoring: \(error.localizedDescription)")
            }
        }
    }
    
    private func processTCCLogOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            guard let request = parser.parseLogLine(line) else {
                continue
            }
            
            DispatchQueue.main.async { [weak self] in
                // Notify observers
                self?.onRequestReceived?(request)
                self?.onStatusChange?("Latest: \(request.processName) requested \(request.serviceName)")
                
                // Send notification
                self?.notificationService.sendNotification(for: request)
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
