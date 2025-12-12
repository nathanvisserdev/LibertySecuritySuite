# Liberty Access Control

<div align="center">

![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-purple.svg)

**A comprehensive macOS security and privacy management suite**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Architecture](#architecture) • [Contributing](#contributing)

</div>

---

## 🎯 Overview

Liberty Access Control is a native macOS application that provides advanced security monitoring, privacy management, and system access control. Built with SwiftUI and modern macOS frameworks, it gives users unprecedented visibility and control over their system's security posture.

### Why Liberty Access Control?

- **🔍 TCC Database Visibility**: View and manage all Transparency, Consent, and Control (TCC) permissions
- **🛡️ Real-time Security Monitoring**: Track suspicious processes, file system changes, and network activity
- **🚫 Permission Blacklisting**: Revoke and permanently block unwanted app permissions
- **📊 Comprehensive Dashboard**: Unified view of your system's security status
- **🔐 Authentication & Encryption**: Secure notes with local authentication and encryption
- **🌐 Network Monitoring**: Track and control network connections and firewall rules

---

## ✨ Features

### TCC Database Management
- **View All Permissions**: Browse both User and System TCC databases
- **Permission Details**: See authorization status, service types, and timestamps
- **Bulk Operations**: Grant, revoke, or reset permissions across multiple apps
- **Search & Filter**: Quickly find specific apps or permission types

### Security Monitoring
- **Process Monitor**: Real-time tracking of running processes and system events
- **File System Monitor**: Track file creation, modification, and deletion events
- **Threat Detection**: Scan for suspicious activity in critical system locations
- **Malware Scanner**: Identify potentially malicious applications
- **Network Firewall**: Monitor and control network connections

### Permission Blacklisting
- **Auto-Revocation**: Automatically block attempts to regain revoked permissions
- **Attempt Logging**: Track all blacklist violation attempts
- **Persistent Enforcement**: Continuous monitoring of both User and System TCC databases
- **Notification System**: Get alerted when apps try to bypass restrictions

### Secure Notes
- **Encrypted Storage**: AES-256 encryption with secure key derivation
- **Biometric Auth**: Face ID/Touch ID protection for sensitive notes
- **Version Control**: Git-based versioning for note history
- **Search**: Fast full-text search across all notes

### Network Management
- **Connection Tracking**: Monitor all active network connections
- **Firewall Integration**: View and manage macOS firewall rules
- **Traffic Analysis**: Identify suspicious network activity
- **DNS Monitoring**: Track DNS queries and responses

---

## 🚀 Installation

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building from source)
- Apple Developer account (for code signing)

### Building from Source

1. **Clone the repository**
```bash
git clone https://github.com/nathanvisserdev/LibertySecuritySuite.git
cd LibertySecuritySuite
```

2. **Open in Xcode**
```bash
open LibertyAccessControl.xcodeproj
```

3. **Configure code signing**
   - Select the project in Xcode
   - Update the Team and Bundle Identifier in Signing & Capabilities
   - Ensure entitlements are properly configured

4. **Build and run**
   - Select your target device (My Mac)
   - Press `Cmd + R` to build and run

### First Launch Setup

On first launch, you'll need to grant the following permissions:
- **Full Disk Access**: Required to read TCC databases
- **Accessibility**: Needed for system monitoring features
- **System Events**: For process monitoring

Navigate to **System Settings > Privacy & Security** and grant the necessary permissions.

---

## 📖 Usage

### Viewing TCC Permissions

1. Navigate to **TCC Database Viewer** from the sidebar
2. Select User or System database
3. Browse permissions by service type or search for specific apps
4. Click on any entry to view detailed information

### Revoking Permissions

1. Select the permission you want to revoke
2. Click **Revoke Permission**
3. Optionally enable **Add to Blacklist** to prevent re-authorization
4. Confirm the action

### Monitoring Security Threats

1. Go to **Security Monitor** in the sidebar
2. Click **Start Monitoring**
3. Review detected threats in real-time
4. Click on threats for detailed information and remediation options

### Managing Network Activity

1. Open **Network & Firewall** view
2. View active connections and firewall rules
3. Block suspicious connections or modify firewall rules
4. Monitor network traffic patterns

### Creating Secure Notes

1. Navigate to **Secure Notes**
2. Authenticate with biometrics
3. Create new notes with the **+** button
4. Notes are automatically encrypted and version-controlled

---

## 🏗️ Architecture

### Project Structure

```
LibertyAccessControl/
├── LibertyAccessControl/          # Main application
│   ├── Models/                    # Data models
│   │   ├── Permissions/           # TCC permission models
│   │   ├── BlacklistEntry.swift   # Blacklist data model
│   │   ├── ProcessEvent.swift     # Process monitoring models
│   │   └── FileSystemEvent.swift  # File system event models
│   ├── Services/                  # Business logic layer
│   │   ├── AuthorizationService.swift      # TCC authorization
│   │   ├── BlacklistService.swift          # Blacklist management
│   │   ├── BlacklistEnforcementService.swift # Auto-revocation
│   │   ├── SecurityMonitor.swift           # Security scanning
│   │   ├── ProcessMonitorService.swift     # Process tracking
│   │   ├── FileSystemMonitorService.swift  # FS monitoring
│   │   ├── NetworkMonitor.swift            # Network tracking
│   │   ├── MalwareScannerService.swift     # Malware detection
│   │   ├── TCCCacheReader.swift            # TCC database access
│   │   └── SecureNotesService.swift        # Note encryption
│   ├── Views/                     # SwiftUI views
│   │   ├── HomeView.swift
│   │   ├── DashboardView.swift
│   │   ├── SecurityMonitorView.swift
│   │   ├── NetworkMonitorView.swift
│   │   └── FileSystemMonitorView.swift
│   ├── Components/                # Reusable UI components
│   └── DTOs/                      # Data transfer objects
├── PrivilegedHelper/              # Elevated privilege helper
└── Tests/                         # Unit and UI tests
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Core Data**: File system event persistence
- **Security Framework**: Encryption and authentication
- **EndpointSecurity**: System event monitoring (planned)
- **Network Framework**: Network connection tracking
- **FileSystemEvents**: Real-time file system monitoring

### Services Overview

#### TCCCacheReader
Reads and parses the TCC database directly without relying on system daemons. Handles both User and System TCC databases with proper permission handling.

#### BlacklistEnforcementService
Continuously monitors TCC databases for blacklisted permissions that have been re-granted. Automatically revokes them and logs attempts for audit purposes.

#### SecurityMonitor
Scans critical system locations for suspicious files, tracks modifications to launch agents/daemons, and identifies potential threats based on heuristics.

#### ProcessMonitorService
Tracks process launches and exits, maintains process history, and can identify suspicious process behaviors (planned integration with EndpointSecurity framework).

#### NetworkMonitor
Monitors active network connections, integrates with the macOS firewall, and can identify suspicious network activity patterns.

---

## 🔒 Security & Privacy

### Data Storage

- **TCC Data**: Read-only access to system TCC databases; no modifications without explicit user action
- **Blacklist**: Stored in secure UserDefaults with encryption
- **Secure Notes**: AES-256 encryption with keys derived from user authentication
- **Logs**: All monitoring logs stored locally with configurable retention

### Permissions Required

Liberty Access Control requires the following permissions:

| Permission | Purpose | Required |
|------------|---------|----------|
| Full Disk Access | Read TCC databases | Yes |
| Accessibility | Monitor system events | Optional |
| Screen Recording | Capture process info (planned) | No |

### Privacy Commitment

- **No telemetry**: All data stays on your device
- **No network calls**: No external servers or analytics
- **Open source**: Fully auditable codebase
- **User control**: All monitoring features can be disabled

---

## 🛠️ Development

### Prerequisites

- Xcode 15.0+
- macOS 14.0+ SDK
- Swift 5.9+

### Building

```bash
# Clone the repository
git clone https://github.com/nathanvisserdev/LibertySecuritySuite.git
cd LibertySecuritySuite

# Open in Xcode
open LibertyAccessControl.xcodeproj

# Build
xcodebuild -scheme LibertyAccessControl -configuration Debug build
```

### Running Tests

```bash
xcodebuild test -scheme LibertyAccessControl -destination 'platform=macOS'
```

### Code Style

This project follows Swift best practices and conventions:
- SwiftLint for style enforcement (configuration in progress)
- Comprehensive documentation for public APIs
- MVVM architecture pattern

---

## 📝 Roadmap

### Current Features (v1.0)
- ✅ TCC database viewer
- ✅ Permission revocation with blacklisting
- ✅ Security monitoring
- ✅ File system event tracking
- ✅ Network monitoring
- ✅ Secure notes with encryption

### Planned Features (v1.1)
- 🔄 EndpointSecurity framework integration
- 🔄 Advanced threat detection with ML
- 🔄 Custom rule engine for automation
- 🔄 Export/import configurations
- 🔄 Scheduled security scans

### Future Considerations (v2.0)
- 📋 System extension for deeper integration
- 📋 Remote management capabilities
- 📋 Compliance reporting
- 📋 Integration with XProtect

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Code Guidelines

- Follow Swift API Design Guidelines
- Include unit tests for new features
- Update documentation for public APIs
- Ensure all tests pass before submitting PR

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Apple's TCC system documentation
- macOS security research community
- SwiftUI community for UI inspiration

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/nathanvisserdev/LibertySecuritySuite/issues)
- **Discussions**: [GitHub Discussions](https://github.com/nathanvisserdev/LibertySecuritySuite/discussions)

---

<div align="center">

**Built with ❤️ for macOS security enthusiasts**

⭐ Star this repo if you find it useful!

</div>
