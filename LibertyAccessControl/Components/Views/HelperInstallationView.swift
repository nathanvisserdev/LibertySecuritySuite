import SwiftUI

struct HelperInstallationView: View {
    @ObservedObject var helperManager: PrivilegedHelperManager
    @State private var isInstalling = false
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status section
            GroupBox(label: Label("Helper Tool Status", systemImage: "gearshape.2.fill")) {
                VStack(alignment: .leading, spacing: 12) {
                    statusRow
                    
                    if let version = helperManager.currentVersion {
                        HStack {
                            Text("Version:")
                                .fontWeight(.medium)
                            Text(version)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    if let error = helperManager.errorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(8)
            }
            
            // Information section
            GroupBox(label: Label("About Privileged Helper", systemImage: "info.circle")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The privileged helper tool enables process monitoring by:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        InfoPoint(text: "Running with system-level privileges")
                        InfoPoint(text: "Using Apple's EndpointSecurity framework")
                        InfoPoint(text: "Monitoring all process executions in real-time")
                        InfoPoint(text: "Validating code signatures and detecting threats")
                    }
                    .padding(.leading, 8)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Security Features:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        InfoPoint(text: "Isolated in separate process")
                        InfoPoint(text: "Signed and verified by macOS")
                        InfoPoint(text: "Communicates via secure XPC")
                        InfoPoint(text: "Can only be installed with your password")
                    }
                    .padding(.leading, 8)
                }
                .padding(8)
            }
            
            // Action button
            actionButton
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 600)
    }
    
    private var statusRow: some View {
        HStack {
            Text("Status:")
                .fontWeight(.medium)
            statusBadge
            Spacer()
        }
    }
    
    private var statusBadge: some View {
        Group {
            switch helperManager.installationStatus {
            case .notInstalled:
                Label("Not Installed", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .installed:
                Label("Installed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .needsUpdate:
                Label("Update Available", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundColor(.orange)
            case .installedButNotRunning:
                Label("Not Running", systemImage: "pause.circle.fill")
                    .foregroundColor(.yellow)
            }
        }
        .font(.subheadline)
    }
    
    private var actionButton: some View {
        Group {
            switch helperManager.installationStatus {
            case .notInstalled:
                Button(action: installHelper) {
                    HStack {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isInstalling ? "Installing..." : "Install Helper Tool")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling)
                
            case .needsUpdate:
                Button(action: installHelper) {
                    HStack {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(isInstalling ? "Updating..." : "Update Helper Tool")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling)
                
            case .installed:
                HStack(spacing: 12) {
                    Button(action: { helperManager.checkInstallationStatus() }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Status")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
            case .installedButNotRunning:
                VStack(spacing: 8) {
                    Text("Helper tool is installed but not responding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: installHelper) {
                        HStack {
                            if isInstalling {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(isInstalling ? "Reinstalling..." : "Reinstall Helper")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                }
            }
        }
    }
    
    private func installHelper() {
        isInstalling = true
        
        helperManager.installHelper { result in
            DispatchQueue.main.async {
                isInstalling = false
                
                switch result {
                case .success():
                    print("✅ Helper installed successfully")
                    // Refresh status after successful installation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        helperManager.checkInstallationStatus()
                    }
                case .failure(let error):
                    print("❌ Installation failed: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
    }
}

struct InfoPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HelperInstallationView(helperManager: PrivilegedHelperManager())
}
