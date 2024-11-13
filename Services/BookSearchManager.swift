import Foundation

class BookSearchManager: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    private let sourceManager: BookSourceManager
    private let parser: BookSourceParser
    
    init(sourceManager: BookSourceManager) {
        self.sourceManager = sourceManager
        self.parser = BookSourceParser.shared
    }
    
    func search(keyword: String) async {
        guard !keyword.isEmpty else { return }
        
        await MainActor.run { isSearching = true }
        
        let enabledSources = sourceManager.sources.filter { $0.enabled }
        var results: [SearchResult] = []
        
        await withTaskGroup(of: [SearchResult].self) { group in
            for source in enabledSources {
                group.addTask {
                    do {
                        let searchUrl = source.searchUrl.replacingOccurrences(of: "{keyword}", with: keyword)
                        guard let url = URL(string: searchUrl) else { return [] }
                        
                        let html = try await NetworkManager.shared.fetchHTML(url)
                        return try self.parser.parseSearchResults(html: html, rule: source.searchRule, source: source)
                    } catch {
                        print("Search error for source \(source.name): \(error)")
                        return []
                    }
                }
            }
            
            for await sourceResults in group {
                results.append(contentsOf: sourceResults)
            }
        }
        
        await MainActor.run {
            self.searchResults = results
            self.isSearching = false
        }
    }
} 