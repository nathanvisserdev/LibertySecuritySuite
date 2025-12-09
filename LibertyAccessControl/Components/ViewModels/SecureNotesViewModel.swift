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
    
    private let service = SecureNotesService.shared
    
    init() {
        loadNotes()
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
