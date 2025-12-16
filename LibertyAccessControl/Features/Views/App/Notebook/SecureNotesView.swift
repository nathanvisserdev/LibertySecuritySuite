//
//  SecureNotesView.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import SwiftUI

struct SecureNotesView: View {
    @StateObject private var viewModel = SecureNotesViewModel()
    @State private var editingNote: SecureNote?
    @State private var showingShortcuts = false
    
    var body: some View {
        NavigationSplitView {
            // Notes list sidebar
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search notes...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            viewModel.performSearch()
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: viewModel.clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .padding()
                
                Divider()
                
                // Notes list
                if viewModel.notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(viewModel.isSearching ? "No notes found" : "No notes yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(viewModel.isSearching ? "Try a different search" : "Click + to create your first note")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $viewModel.selectedNote) {
                        ForEach(viewModel.filteredNotes) { note in
                            NoteRowView(note: note)
                                .tag(note)
                        }
                        .onDelete(perform: viewModel.deleteNotes)
                    }
                    .listStyle(.sidebar)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: viewModel.createNewNote) {
                        Label("New Note", systemImage: "plus")
                    }
                    .help("Create a new note")
                    .keyboardShortcut("n", modifiers: .command)
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { viewModel.verifyIntegrity() }) {
                        Label("Verify Integrity", systemImage: "checkmark.shield")
                    }
                    .help("Check database integrity against USB backup")
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingShortcuts = true }) {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                    }
                    .help("View keyboard shortcuts")
                    .keyboardShortcut("/", modifiers: .command)
                }
                
                ToolbarItem(placement: .status) {
                    if let status = viewModel.integrityStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("✅") ? .green : .red)
                    } else {
                        Text("\(viewModel.notesCount) \(viewModel.notesCount == 1 ? "note" : "notes")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Secure Notes")
            .sheet(isPresented: $showingShortcuts) {
                KeyboardShortcutsView()
            }
            .sheet(isPresented: $viewModel.showCommitDialog) {
                CommitDialogView(
                    commitMessage: $viewModel.commitMessage,
                    onCommit: { viewModel.commitChanges() },
                    onCancel: { viewModel.showCommitDialog = false }
                )
            }
            
        } detail: {
            // Note editor
            if let selectedNote = viewModel.selectedNote {
                NoteEditorView(note: selectedNote) { updatedNote in
                    viewModel.updateNote(updatedNote)
                } onDelete: {
                    viewModel.deleteNote(selectedNote)
                } onSaveCommit: { message in
                    viewModel.commitMessage = message
                    viewModel.commitChanges()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a note or create a new one")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Note Row View

struct NoteRowView: View {
    let note: SecureNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text(note.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if !note.tags.isEmpty {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if note.tags.count > 2 {
                            Text("+\(note.tags.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Note Editor View

struct NoteEditorView: View {
    @State private var note: SecureNote
    @State private var newTag: String = ""
    @State private var showCommitDialog = false
    @State private var commitMessage = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    let onUpdate: (SecureNote) -> Void
    let onDelete: () -> Void
    let onSaveCommit: (String) -> Void
    
    init(note: SecureNote, onUpdate: @escaping (SecureNote) -> Void, onDelete: @escaping () -> Void, onSaveCommit: @escaping (String) -> Void) {
        _note = State(initialValue: note)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onSaveCommit = onSaveCommit
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            TextField("Note Title", text: $note.title)
                .font(.title)
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .padding()
                .onChange(of: note.title) { _, _ in
                    saveNote()
                }
            
            Divider()
            
            // Tags
            if !note.tags.isEmpty || !newTag.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button(action: { removeTag(tag) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                        }
                        
                        // Add tag field
                        TextField("Add tag...", text: $newTag)
                            .textFieldStyle(.plain)
                            .frame(width: 100)
                            .onSubmit {
                                addTag()
                            }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 40)
                
                Divider()
            }
            
            // Content
            TextEditor(text: $note.content)
                .font(.body)
                .padding()
                .focused($isContentFocused)
                .onChange(of: note.content) { _, _ in
                    saveNote()
                }
            
            Divider()
            
            // Footer with metadata
            HStack {
                // Unsaved changes indicator
                if note.hasUnsavedChanges {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.orange)
                        Text("Modified")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text("Created: \(note.createdAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Modified: \(note.updatedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete note")
                .keyboardShortcut(.delete, modifiers: .command)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onSaveAndCommit) {
                    Label("Save & Commit", systemImage: "square.and.arrow.down")
                }
                .help("Save note and commit to version control")
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!note.hasUnsavedChanges)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { newTag = newTag.isEmpty ? " " : "" }) {
                    Label("Add Tag", systemImage: "tag")
                }
                .help("Add tags to organize notes")
                .keyboardShortcut("t", modifiers: .command)
            }
        }
        .background(
            Group {
                Button("") { insertMarkdown("# ") }
                    .keyboardShortcut("h", modifiers: [.shift, .command])
                    .hidden()
                
                Button("") { insertMarkdown("## ") }
                    .keyboardShortcut("t", modifiers: [.shift, .command])
                    .hidden()
                
                Button("") { insertMarkdown("```\n", "\n```") }
                    .keyboardShortcut("m", modifiers: [.shift, .command])
                    .hidden()
                
                Button("") { wrapSelection("**", "**") }
                    .keyboardShortcut("b", modifiers: .command)
                    .hidden()
                
                Button("") { wrapSelection("*", "*") }
                    .keyboardShortcut("i", modifiers: .command)
                    .hidden()
            }
        )
        .sheet(isPresented: $showCommitDialog) {
            CommitDialogView(
                commitMessage: $commitMessage,
                onCommit: {
                    onSaveCommit(commitMessage)
                    showCommitDialog = false
                },
                onCancel: { showCommitDialog = false }
            )
        }
    }
    
    private func onSaveAndCommit() {
        showCommitDialog = true
    }
    
    private func insertMarkdown(_ prefix: String, _ suffix: String = "") {
        guard isContentFocused else { return }
        
        // Get current cursor position (simplified - inserts at end)
        let newText: String
        if suffix.isEmpty {
            newText = note.content + "\n\(prefix)"
        } else {
            newText = note.content + "\n\(prefix)\(suffix)"
        }
        note.content = newText
        saveNote()
    }
    
    private func wrapSelection(_ prefix: String, _ suffix: String) {
        // For TextEditor, we'll insert at the end with the wrapper
        note.content += "\n\(prefix)Text\(suffix)"
        saveNote()
    }
    
    private func saveNote() {
        note.updatedAt = Date()
        onUpdate(note)
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !note.tags.contains(trimmed) {
            note.tags.append(trimmed)
            newTag = ""
            saveNote()
        }
    }
    
    private func removeTag(_ tag: String) {
        note.tags.removeAll { $0 == tag }
        saveNote()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Keyboard Shortcuts View

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // General
                    ShortcutSection(title: "General") {
                        ShortcutRow(keys: ["⌘", "N"], description: "Create new note")
                        ShortcutRow(keys: ["⌘", "T"], description: "Add tag to note")
                        ShortcutRow(keys: ["⌘", "⌫"], description: "Delete current note")
                        ShortcutRow(keys: ["⌘", "/"], description: "Show keyboard shortcuts")
                    }
                    
                    // Text Formatting (Markdown)
                    ShortcutSection(title: "Text Formatting") {
                        ShortcutRow(keys: ["⇧", "⌘", "H"], description: "Insert heading (# Heading)")
                        ShortcutRow(keys: ["⇧", "⌘", "T"], description: "Insert title (## Title)")
                        ShortcutRow(keys: ["⇧", "⌘", "M"], description: "Insert code block (```)")
                        ShortcutRow(keys: ["⌘", "B"], description: "Insert bold (**text**)")
                        ShortcutRow(keys: ["⌘", "I"], description: "Insert italic (*text*)")
                    }
                    
                    // Markdown Tips
                    ShortcutSection(title: "Markdown Tips") {
                        VStack(alignment: .leading, spacing: 12) {
                            MarkdownTip(syntax: "# Heading", description: "Large heading")
                            MarkdownTip(syntax: "## Title", description: "Medium heading")
                            MarkdownTip(syntax: "### Subtitle", description: "Small heading")
                            MarkdownTip(syntax: "**bold**", description: "Bold text")
                            MarkdownTip(syntax: "*italic*", description: "Italic text")
                            MarkdownTip(syntax: "`code`", description: "Inline code")
                            MarkdownTip(syntax: "```code block```", description: "Code block")
                            MarkdownTip(syntax: "- item", description: "Bullet list")
                            MarkdownTip(syntax: "1. item", description: "Numbered list")
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
    }
}

struct ShortcutSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShortcutRow: View {
    let keys: [String]
    let description: String
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                }
            }
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct MarkdownTip: View {
    let syntax: String
    let description: String
    
    var body: some View {
        HStack {
            Text(syntax)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Commit Dialog View

struct CommitDialogView: View {
    @Binding var commitMessage: String
    let onCommit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isMessageFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Save & Commit")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Add a commit message to describe your changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Commit message field
            VStack(alignment: .leading, spacing: 8) {
                Text("Commit Message:")
                    .font(.headline)
                
                TextEditor(text: $commitMessage)
                    .font(.body)
                    .focused($isMessageFocused)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                Text("Example: \"Added project notes\" or \"Updated research findings\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Actions
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Commit") {
                    onCommit()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 450, height: 280)
        .onAppear {
            isMessageFocused = true
        }
    }
}

#Preview {
    SecureNotesView()
}
