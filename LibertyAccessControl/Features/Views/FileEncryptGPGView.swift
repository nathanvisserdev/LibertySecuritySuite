//
//  FileEncryptGPGView.swift
//  LibertyAccessControl
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FileEncryptGPGView: View {
    @StateObject private var viewModel = FileEncryptGPGViewModel()

    // Helper to copy to clipboard
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("GPG File Encrypt")
                            .font(.title2.bold())
                        Text("Encrypt files using OpenPGP public keys")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.selectFile() }) {
                        Label("Select File", systemImage: "doc")
                    }
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected File")
                        .font(.headline)
                    Text(viewModel.selectedFileURL?.path ?? "No file selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Saved Public Keys")
                        .font(.headline)

                    if viewModel.savedKeys.isEmpty {
                        Text("No saved public keys. Paste a public key below to save or use immediately.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        List(selection: Binding(get: { viewModel.selectedKeyId }, set: { viewModel.selectedKeyId = $0 })) {
                            ForEach(viewModel.savedKeys) { key in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(key.name)
                                        Text(key.addedDate, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .tag(key.id)
                            }
                        }
                        .frame(height: 160)
                    }
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste Public Key (ASCII-armored)")
                        .font(.headline)
                    TextEditor(text: $viewModel.pastedKey)
                        .border(Color.gray.opacity(0.2))
                        .frame(height: 160)

                    HStack(spacing: 8) {
                        TextField("Key name (e.g. Work Key)", text: $viewModel.keyName)
                            .textFieldStyle(.roundedBorder)

                        Button("Import Key File") {
                            viewModel.importKeyFromFile()
                        }
                    }

                    HStack {
                        Button("Save Pasted Key") {
                            viewModel.requestSavePastedKey()
                        }
                        Spacer()
                        Button("Encrypt File") {
                            viewModel.encryptUsingSelectedKey()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }

                // Prompt sheet for name when saving without a name
                .sheet(isPresented: $viewModel.showNamePrompt) {
                    VStack(spacing: 16) {
                        Text("Name this key")
                            .font(.headline)

                        TextField("Enter key name", text: $viewModel.keyName)
                            .textFieldStyle(.roundedBorder)
                            .padding()

                        HStack {
                            Button("Cancel") {
                                viewModel.showNamePrompt = false
                            }
                            Spacer()
                            Button("Save") {
                                let name = viewModel.keyName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if name.isEmpty {
                                    // force input — do nothing (keeps sheet open)
                                } else {
                                    viewModel.confirmSavePastedKey(withName: name)
                                }
                            }
                            .keyboardShortcut(.defaultAction)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .frame(width: 420, height: 200)
                }
                .padding()
            }
            .frame(minWidth: 360)
        } detail: {
            HStack(spacing: 16) {
                // Main detail column
                VStack(spacing: 16) {
                    if viewModel.isProcessing {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(.linear)
                            .padding()

                        Text(viewModel.currentOperation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 64))
                                .foregroundColor(.blue)

                            Text("Ready to encrypt")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)

                Divider()

                // Help / commands panel
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick GPG Commands")
                        .font(.headline)

                    Group {
                        CommandRow(title: "Export public key (ASCII)", command: "gpg --armor --export <FINGERPRINT> > ~/Desktop/my-public-key.asc")
                        CommandRow(title: "Import public key from file", command: "gpg --import /path/to/publickey.asc")
                        CommandRow(title: "Encrypt file to recipient", command: "gpg --output file.txt.gpg --encrypt --recipient <FINGERPRINT> file.txt")
                        CommandRow(title: "Symmetric (passphrase) encrypt", command: "gpg --symmetric file.txt")
                        CommandRow(title: "Decrypt file", command: "gpg --output file.txt --decrypt file.txt.gpg")
                        CommandRow(title: "Decrypt (short)", command: "gpg --decrypt file.txt.gpg")
                        CommandRow(title: "Decrypt (explicit output)", command: "gpg --output file.txt --decrypt file.txt.gpg")
                    }

                    Divider()

                    Text("Locate your keys")
                        .font(.headline)

                    CommandRow(title: "List public keys", command: "gpg --list-keys")
                    CommandRow(title: "List private/secret keys", command: "gpg --list-secret-keys")
                    CommandRow(title: "Show fingerprints", command: "gpg --fingerprint --list-keys")

                    Text("On macOS your GnuPG home directory is typically:\n~/.gnupg\nImportant files:\n• ~/.gnupg/pubring.kbx (public keys)\n• ~/.gnupg/private-keys-v1.d/ (secret key material)\nDo not edit these files directly; use the gpg CLI to manage keys.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                    Text("Home: \(FileManager.default.homeDirectoryForCurrentUser.path)/.gnupg")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(width: 380)
            }
            .padding()
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    FileEncryptGPGView()
}

fileprivate struct CommandRow: View {
    let title: String
    let command: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 6)
    }
}
