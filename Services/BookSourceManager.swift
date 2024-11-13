import Foundation

class BookSourceManager: ObservableObject {
    @Published var sources: [BookSource] = []
    private let storageManager = StorageManager.shared
    
    init() {
        loadSources()
        if sources.isEmpty {
            importDefaultSources()
        }
    }
    
    // 从本地加载书源
    private func loadSources() {
        if let data = storageManager.getData(forKey: "book_sources"),
           let sources = try? JSONDecoder().decode([BookSource].self, from: data) {
            self.sources = sources
        }
    }
    
    // 保存书源到本地
    private func saveSources() {
        if let data = try? JSONEncoder().encode(sources) {
            storageManager.save(data, forKey: "book_sources")
        }
    }
    
    // 导入默认书源
    private func importDefaultSources() {
        Task {
            do {
                let url = URL(string: "https://www.yckceo.com/yuedu/shuyuans/json/id/656.json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let sources = try JSONDecoder().decode([BookSource].self, from: data)
                await MainActor.run {
                    self.sources = sources
                    self.saveSources()
                }
            } catch {
                print("Failed to import default sources: \(error)")
            }
        }
    }
    
    // 添加书源
    func addSource(_ source: BookSource) {
        if !sources.contains(where: { $0.url == source.url }) {
            sources.append(source)
            saveSources()
        }
    }
    
    // 删除书源
    func removeSource(_ source: BookSource) {
        sources.removeAll { $0.id == source.id }
        saveSources()
    }
    
    // 更新书源状态
    func updateSourceStatus(_ source: BookSource, enabled: Bool) {
        if let index = sources.firstIndex(where: { $0.id == source.id }) {
            var updatedSource = source
            updatedSource.enabled = enabled
            sources[index] = updatedSource
            saveSources()
        }
    }
    
    // 更新书源
    func updateSource(_ source: BookSource) {
        if let index = sources.firstIndex(where: { $0.id == source.id }) {
            sources[index] = source
            saveSources()
        }
    }
    
    // 导入书源
    func importSources(from url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let sources = try JSONDecoder().decode([BookSource].self, from: data)
        await MainActor.run {
            sources.forEach { addSource($0) }
        }
    }
    
    // 测试书源
    func testSource(_ source: BookSource) async -> Bool {
        do {
            return try await BookSourceTester.shared.testSource(source).isSuccessful
        } catch {
            return false
        }
    }
    
    // 批量导入书源
    func importSources(_ sources: [BookSource]) {
        sources.forEach { addSource($0) }
    }
    
    // 导出书源
    func exportSources() -> Data? {
        try? JSONEncoder().encode(sources)
    }
    
    // 清空所有书源
    func clearSources() {
        sources.removeAll()
        saveSources()
    }
} 