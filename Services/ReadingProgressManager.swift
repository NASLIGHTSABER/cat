import Foundation
import CoreData

class ReadingProgressManager {
    static let shared = ReadingProgressManager()
    private let storageManager = StorageManager.shared
    
    func saveProgress(for book: Book, chapter: Chapter, position: Double) {
        let context = storageManager.context
        
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            let bookEntity: BookEntity
            
            if let existingBook = results.first {
                bookEntity = existingBook
            } else {
                bookEntity = BookEntity(context: context)
                bookEntity.id = book.id
                bookEntity.title = book.title
                bookEntity.author = book.author
                bookEntity.coverUrl = book.coverUrl
            }
            
            bookEntity.lastReadChapter = chapter.title
            bookEntity.lastReadTime = Date()
            
            try context.save()
        } catch {
            print("Error saving reading progress: \(error)")
        }
    }
    
    func getProgress(for book: Book) -> (chapter: String?, position: Double)? {
        let context = storageManager.context
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let bookEntity = results.first {
                return (bookEntity.lastReadChapter, 0.0) // 可以添加具体位置的存储
            }
        } catch {
            print("Error fetching reading progress: \(error)")
        }
        
        return nil
    }
} 