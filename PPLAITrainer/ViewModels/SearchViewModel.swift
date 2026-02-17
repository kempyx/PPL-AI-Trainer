import SwiftUI
import os

@Observable
class SearchViewModel {
    private let databaseManager: DatabaseManaging
    private let logger = Logger(subsystem: "com.pplaitrainer", category: "SearchViewModel")
    
    var searchText = ""
    var results: [Question] = []
    var isSearching = false
    
    private var searchTask: Task<Void, Never>?
    
    init(databaseManager: DatabaseManaging) {
        self.databaseManager = databaseManager
    }
    
    func search() {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            results = []
            return
        }
        
        searchTask = Task {
            isSearching = true
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            do {
                let found = try databaseManager.searchQuestions(query: searchText, limit: 50)
                await MainActor.run {
                    results = found
                    isSearching = false
                }
            } catch {
                logger.error("Search failed: \(error)")
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }
}
