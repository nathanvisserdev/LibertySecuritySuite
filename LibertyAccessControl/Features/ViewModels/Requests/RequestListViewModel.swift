//
//  RequestListViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Combine

@MainActor
class RequestListViewModel: ObservableObject {
    @Published var model = RequestListModel()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadData() {
        Task {
            await fetchData()
        }
    }
    
    private func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            // Model will handle the service layer request
//            try await model.fetchRequests()
        } catch {
            errorMessage = "Failed to fetch requests: \(error.localizedDescription)"
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
