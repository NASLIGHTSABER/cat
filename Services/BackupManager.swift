import Foundation
import CoreData

class BackupManager {
    static let shared = BackupManager()
    private let fileManager = FileManager.default
    
    private var backupDirectory: URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("Backups")
    }
    
    func backup() async throws {
        // 确保备份目录存在
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        let backupData = BackupData(
            books: try await exportBooks(),
            sources: BookSourceManager().sources,
            settings: exportSettings()
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backupData)
        
        let backupFile = backupDirectory.appendingPathComponent("backup_\(Date().timeIntervalSince1970).json")
        try data.write(to: backupFile)
    }
    
    func restore() async throws {
        let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
        guard let latestBackup = backupFiles.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first else {
            throw BackupError.noBackupFound
        }
        
        let data = try Data(contentsOf: latestBackup)
        let backupData = try JSONDecoder().decode(BackupData.self, from: data)
        
        // 恢复数据
        try await importBooks(backupData.books)
        BookSourceManager().sources = backupData.sources
        importSettings(backupData.settings)
    }
    
    private func exportBooks() async throws -> [Book] {
        // 从 CoreData 导出书籍数据
        let context = StorageManager.shared.context
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let books = try context.fetch(fetchRequest)
        
        return books.map { entity in
            Book(
                title: entity.title ?? "",
                author: entity.author ?? "",
                coverUrl: entity.coverUrl,
                lastReadChapter: entity.lastReadChapter ?? "",
                lastReadTime: entity.lastReadTime ?? Date()
            )
        }
    }
    
    private func importBooks(_ books: [Book]) async throws {
        let context = StorageManager.shared.context
        
        // 清除现有数据
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = BookEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        
        // 导入新数据
        for book in books {
            let entity = BookEntity(context: context)
            entity.id = book.id
            entity.title = book.title
            entity.author = book.author
            entity.coverUrl = book.coverUrl
            entity.lastReadChapter = book.lastReadChapter
            entity.lastReadTime = book.lastReadTime
        }
        
        try context.save()
    }
    
    private func exportSettings() -> [String: Any] {
        let defaults = UserDefaults.standard
        return [
            "theme": defaults.string(forKey: "theme") ?? "system",
            "fontSize": defaults.double(forKey: "fontSize"),
            "autoBackup": defaults.bool(forKey: "autoBackup")
        ]
    }
    
    private func importSettings(_ settings: [String: Any]) {
        let defaults = UserDefaults.standard
        settings.forEach { key, value in
            defaults.set(value, forKey: key)
        }
    }
}

struct BackupData: Codable {
    let books: [Book]
    let sources: [BookSource]
    let settings: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case books, sources, settings
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(books, forKey: .books)
        try container.encode(sources, forKey: .sources)
        try container.encode(settings as? [String: String], forKey: .settings)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        books = try container.decode([Book].self, forKey: .books)
        sources = try container.decode([BookSource].self, forKey: .sources)
        settings = try container.decode([String: String].self, forKey: .settings)
    }
    
    init(books: [Book], sources: [BookSource], settings: [String: Any]) {
        self.books = books
        self.sources = sources
        self.settings = settings
    }
}

enum BackupError: Error {
    case noBackupFound
} 