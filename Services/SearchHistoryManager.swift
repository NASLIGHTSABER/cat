import Foundation

class SearchHistoryManager: ObservableObject {
    static let shared = SearchHistoryManager()
    @Published private(set) var history: [String] = []
    private let maxHistoryItems = 20
    private let storageKey = "SearchHistory"
    
    init() {
        loadHistory()
    }
    
    func addSearch(_ keyword: String) {
        if let index = history.firstIndex(of: keyword) {
            history.remove(at: index)
        }
        history.insert(keyword, at: 0)
        
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func removeItem(_ keyword: String) {
        if let index = history.firstIndex(of: keyword) {
            history.remove(at: index)
            saveHistory()
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
} 