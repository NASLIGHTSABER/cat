import Foundation
import CoreData

class StorageManager {
    static let shared = StorageManager()
    
    private let userDefaults = UserDefaults.standard
    
    // 获取数据
    func getData(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }
    
    // 保存数据
    func save(_ data: Data, forKey key: String) {
        userDefaults.set(data, forKey: key)
    }
    
    // CoreData 相关代码保持不变
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BookModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
} 