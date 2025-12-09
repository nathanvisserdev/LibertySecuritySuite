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
                }
                
                ToolbarItem(placement: .status) {
                    Text("\(viewModel.notesCount) \(viewModel.notesCount == 1 ? "note" : "notes")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Secure Notes")
            
        } detail: {
            // Note editor
            if let selectedNote = viewModel.selectedNote {
                NoteEditorView(note: selectedNote) { updatedNote in
                    viewModel.updateNote(updatedNote)
                } onDelete: {
                    viewModel.deleteNote(selectedNote)
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
    @FocusState private var isTitleFocused: Bool
    
    let onUpdate: (SecureNote) -> Void
    let onDelete: () -> Void
    
    init(note: SecureNote, onUpdate: @escaping (SecureNote) -> Void, onDelete: @escaping () -> Void) {
        _note = State(initialValue: note)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
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
                .onChange(of: note.content) { _, _ in
                    saveNote()
                }
            
            Divider()
            
            // Footer with metadata
            HStack {
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
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { newTag = newTag.isEmpty ? " " : "" }) {
                    Label("Add Tag", systemImage: "tag")
                }
                .help("Add tags to organize notes")
            }
        }
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

#Preview {
    SecureNotesView()
}
