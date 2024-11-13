import Foundation
import SwiftUI

struct Book: Identifiable, Codable {
    var id = UUID()
    var title: String
    var author: String
    var coverUrl: String?
    var lastReadChapter: String
    var lastReadTime: Date
    
    init(id: UUID = UUID(), title: String, author: String, coverUrl: String? = nil, lastReadChapter: String = "", lastReadTime: Date = Date()) {
        self.id = id
        self.title = title
        self.author = author
        self.coverUrl = coverUrl
        self.lastReadChapter = lastReadChapter
        self.lastReadTime = lastReadTime
    }
} 