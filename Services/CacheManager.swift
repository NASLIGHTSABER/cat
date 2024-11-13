import Foundation

class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.reader.cache")
    
    private var memoryCache = NSCache<NSString, NSData>()
    
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("BookCache")
    }
    
    private init() {
        setupCache()
    }
    
    private func setupCache() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 配置内存缓存
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 清理过期缓存
        cleanExpiredCache()
    }
    
    // MARK: - 图片缓存
    
    func cacheImage(_ data: Data, for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.setObject(data as NSData, forKey: key as NSString)
        
        queue.async {
            try? data.write(to: self.cacheDirectory.appendingPathComponent(key))
        }
    }
    
    func getImage(for url: URL) -> Data? {
        let key = cacheKey(for: url)
        
        // 检查内存缓存
        if let data = memoryCache.object(forKey: key as NSString) {
            return data as Data
        }
        
        // 检查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let data = try? Data(contentsOf: fileURL) {
            memoryCache.setObject(data as NSData, forKey: key as NSString)
            return data
        }
        
        return nil
    }
    
    // MARK: - 章节缓存
    
    func cacheChapter(_ content: String, for url: URL) {
        let key = cacheKey(for: url)
        if let data = content.data(using: .utf8) {
            queue.async {
                try? data.write(to: self.cacheDirectory.appendingPathComponent(key))
            }
        }
    }
    
    func getChapter(for url: URL) -> String? {
        let key = cacheKey(for: url)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        return content
    }
    
    // MARK: - 缓存管理
    
    func clearCache() {
        memoryCache.removeAllObjects()
        
        queue.async {
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func cleanExpiredCache() {
        queue.async {
            let expirationDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7天过期
            
            guard let files = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
                return
            }
            
            for file in files {
                guard let attributes = try? self.fileManager.attributesOfItem(atPath: file.path),
                      let creationDate = attributes[.creationDate] as? Date,
                      creationDate < expirationDate else {
                    continue
                }
                try? self.fileManager.removeItem(at: file)
            }
        }
    }
    
    private func cacheKey(for url: URL) -> String {
        return url.absoluteString.replacingOccurrences(of: "/", with: "_")
    }
} 