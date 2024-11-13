import Foundation

class LocalBookManager {
    static let shared = LocalBookManager()
    private let fileManager = FileManager.default
    
    private var booksDirectory: URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("LocalBooks")
    }
    
    init() {
        try? fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
    }
    
    func saveBook(_ book: LocalBook) throws {
        let bookDir = booksDirectory.appendingPathComponent(book.id.uuidString)
        try fileManager.createDirectory(at: bookDir, withIntermediateDirectories: true)
        
        // 保存书籍信息
        let infoData = try JSONEncoder().encode(book)
        try infoData.write(to: bookDir.appendingPathComponent("info.json"))
        
        // 保存内容
        try book.content.write(to: bookDir.appendingPathComponent("content.txt"), atomically: true, encoding: .utf8)
    }
    
    func loadBooks() throws -> [LocalBook] {
        let contents = try fileManager.contentsOfDirectory(at: booksDirectory, includingPropertiesForKeys: nil)
        return try contents.compactMap { url in
            let infoUrl = url.appendingPathComponent("info.json")
            let data = try Data(contentsOf: infoUrl)
            return try JSONDecoder().decode(LocalBook.self, from: data)
        }
    }
    
    func deleteBook(_ book: LocalBook) throws {
        let bookDir = booksDirectory.appendingPathComponent(book.id.uuidString)
        try fileManager.removeItem(at: bookDir)
    }
} 