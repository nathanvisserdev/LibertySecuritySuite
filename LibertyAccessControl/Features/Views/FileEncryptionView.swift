//
//  FileEncryptionView.swift
//  LibertyAccessControl
//
//  Created on 2025-12-12.
//

import SwiftUI

struct FileEncryptionView: View {
    @StateObject private var viewModel = FileEncryptionViewModel()
    
    var body: some View {
        NavigationSplitView {
            // Encrypted files list
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File Encryption")
                            .font(.title2.bold())
                        Text("\(viewModel.encryptedFiles.count) encrypted file(s)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: { viewModel.selectFileToEncrypt() }) {
                            Label("Encrypt File", systemImage: "lock.fill")
                        }
                        
                        Button(action: { viewModel.importEncryptedFile() }) {
                            Label("Decrypt File", systemImage: "lock.open.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 32, height: 32)
                    }
                    .menuStyle(.borderlessButton)
                    .disabled(viewModel.isProcessing)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // Processing progress
                if viewModel.isProcessing {
                    VStack(spacing: 12) {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(.linear)
                        
                        HStack {
                            Text(viewModel.currentOperation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(viewModel.progress * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor))
                    
                    Divider()
                }
                
                // Files list
                if viewModel.encryptedFiles.isEmpty && !viewModel.isProcessing {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Encrypted Files")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Click '+' to encrypt a file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.encryptedFiles, selection: $viewModel.selectedFile) { file in
                        EncryptedFileRowView(file: file)
                            .tag(file)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 350)
            
        } detail: {
            // Detail view
            if let selectedFile = viewModel.selectedFile {
                FileEncryptionDetailView(
                    file: selectedFile,
                    onDecrypt: { viewModel.initiateDecryption(file: selectedFile) },
                    onExport: { viewModel.exportEncryptedFile(selectedFile) },
                    onDelete: { viewModel.confirmDeleteFile(selectedFile) }
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.doc")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select an encrypted file")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Choose a file from the list to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.showEncryptionDialog) {
            EncryptionDialogView(
                fileName: viewModel.selectedFileToEncrypt?.lastPathComponent ?? "",
                password: $viewModel.encryptionPassword,
                passwordConfirm: $viewModel.encryptionPasswordConfirm,
                passwordStrength: viewModel.passwordStrength,
                passwordsMatch: viewModel.passwordsMatch,
                canEncrypt: viewModel.canEncrypt,
                onEncrypt: { viewModel.performEncryption() },
                onCancel: { viewModel.cancelEncryption() }
            )
        }
        .sheet(isPresented: $viewModel.showDecryptionDialog) {
            DecryptionDialogView(
                fileName: viewModel.fileToDecrypt?.originalFileName ?? "",
                password: $viewModel.decryptionPassword,
                onDecrypt: { viewModel.performDecryption() },
                onCancel: { viewModel.cancelDecryption() }
            )
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Delete Encrypted File", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteFile()
            }
        } message: {
            Text("Are you sure you want to delete this encrypted file? This action cannot be undone.")
        }
    }
}

// MARK: - Encrypted File Row

struct EncryptedFileRowView: View {
    let file: EncryptedFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.doc.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.originalFileName)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(file.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct FileEncryptionDetailView: View {
    let file: EncryptedFile
    let onDecrypt: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // File icon and name
                VStack(spacing: 16) {
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text(file.originalFileName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                Divider()
                
                // File information
                VStack(alignment: .leading, spacing: 16) {
                    Text("File Information")
                        .font(.headline)
                    
                    InfoRow(label: "Original Name", value: file.originalFileName)
                    InfoRow(label: "File Size", value: file.formattedSize)
                    InfoRow(label: "Encryption Date", value: file.formattedDate)
                    InfoRow(label: "Algorithm", value: file.algorithm)
                    InfoRow(label: "Location", value: file.encryptedFilePath, isPath: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                Divider()
                
                // Security Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Security Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("256-bit AES-GCM Encryption", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Label("Password-based key derivation (PBKDF2)", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Label("Authenticated encryption with AEAD", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Label("Portable format (decrypt without app)", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onDecrypt) {
                        Label("Decrypt File", systemImage: "lock.open.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: onExport) {
                        Label("Export Encrypted File", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: onDelete) {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .foregroundColor(.red)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    var isPath: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isPath {
                Text(value)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .lineLimit(2)
            } else {
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Encryption Dialog

struct EncryptionDialogView: View {
    let fileName: String
    @Binding var password: String
    @Binding var passwordConfirm: String
    let passwordStrength: PasswordStrength
    let passwordsMatch: Bool
    let canEncrypt: Bool
    let onEncrypt: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Encrypt File")
                    .font(.title2.bold())
                
                Text(fileName)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top)
            
            Divider()
            
            // Password fields
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                    
                    SecureField("Enter password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Strength: \(passwordStrength.description)")
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor)
                        
                        Spacer()
                        
                        if password.count > 0 {
                            Text("\(password.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.headline)
                    
                    SecureField("Re-enter password", text: $passwordConfirm)
                        .textFieldStyle(.roundedBorder)
                    
                    if !passwordConfirm.isEmpty {
                        HStack {
                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(passwordsMatch ? "Passwords match" : "Passwords do not match")
                        }
                        .font(.caption)
                        .foregroundColor(passwordsMatch ? .green : .red)
                    }
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Label("256-bit AES-GCM encryption", systemImage: "lock.shield.fill")
                Label("Password must be at least 8 characters", systemImage: "key.fill")
                Label("File can be decrypted without this app", systemImage: "checkmark.circle.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Encrypt", action: onEncrypt)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canEncrypt)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 450)
    }
    
    private var passwordStrengthColor: Color {
        switch passwordStrength {
        case .empty: return .secondary
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

// MARK: - Decryption Dialog

struct DecryptionDialogView: View {
    let fileName: String
    @Binding var password: String
    let onDecrypt: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Decrypt File")
                    .font(.title2.bold())
                
                Text(fileName)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top)
            
            Divider()
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                
                SecureField("Enter decryption password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Text("The file will be saved to your Downloads folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Label("Enter the password used to encrypt this file", systemImage: "info.circle.fill")
                Label("Decrypted file will retain its original name", systemImage: "doc.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Decrypt", action: onDecrypt)
                    .keyboardShortcut(.defaultAction)
                    .disabled(password.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 450)
    }
}

#Preview {
    FileEncryptionView()
}
