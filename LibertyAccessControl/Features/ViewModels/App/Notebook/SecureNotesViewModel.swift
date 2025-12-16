//
//  SecureNotesViewModel.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SecureNotesViewModel: ObservableObject {
    @Published var notes: [SecureNote] = []
    @Published var selectedNote: SecureNote?
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var integrityStatus: String?
    @Published var showCommitDialog = false
    @Published var commitMessage = ""
    
    private let service = SecureNotesService.shared
    private let gitService = GitVersioningService.shared
    
    init() {
        loadNotes()
        // Don't verify on init - only when user requests it
    }
    
    // MARK: - Git Versioning
    
    func commitChanges() {
        guard !commitMessage.isEmpty else { return }
        
        let result = gitService.commitDatabase(message: commitMessage)
        
        if result.success {
            // Mark current note as saved
            if var note = selectedNote {
                note.markAsSaved()
                updateNote(note)
            }
            
            integrityStatus = "✅ Saved and committed: \(commitMessage)"
            commitMessage = ""
            showCommitDialog = false
        } else {
            integrityStatus = "❌ Commit failed: \(result.error ?? "Unknown error")"
        }
    }
    
    func verifyIntegrity() {
        let result = gitService.verifyIntegrity()
        integrityStatus = result.message
        
        if !result.valid {
            // Show alert for tampering
            print("🚨 Database tampering detected!")
        }
    }
    
    func hasUnsavedChanges() -> Bool {
        return selectedNote?.hasUnsavedChanges ?? false || gitService.hasUncommittedChanges()
    }
    
    // MARK: - Notes Management
    
    func loadNotes() {
        notes = service.loadNotes()
    }
    
    func createNewNote() {
        let newNote = service.createNote()
        notes.insert(newNote, at: 0)
        selectedNote = newNote
    }
    
    func updateNote(_ note: SecureNote) {
        service.updateNote(note)
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
    }
    
    func deleteNote(_ note: SecureNote) {
        service.deleteNote(note)
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = notes.first
        }
    }
    
    func deleteNotes(at offsets: IndexSet) {
        let notesToDelete = offsets.map { notes[$0] }
        let idsToDelete = Set(notesToDelete.map { $0.id })
        
        service.deleteNotes(idsToDelete)
        notes.remove(atOffsets: offsets)
        
        if let selected = selectedNote, idsToDelete.contains(selected.id) {
            selectedNote = notes.first
        }
    }
    
    // MARK: - Search
    
    func performSearch() {
        if searchQuery.isEmpty {
            notes = service.loadNotes()
            isSearching = false
        } else {
            notes = service.searchNotes(query: searchQuery)
            isSearching = true
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        performSearch()
    }
    
    // MARK: - Computed Properties
    
    var filteredNotes: [SecureNote] {
        notes
    }
    
    var notesCount: Int {
        notes.count
    }
}
