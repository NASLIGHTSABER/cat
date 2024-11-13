import Foundation

struct BookSource: Codable, Identifiable, Equatable {
    let id = UUID()
    var name: String
    var url: String
    var searchUrl: String
    var enabled: Bool = true
    var weight: Int = 0
    var header: [String: String]?
    
    // 规则
    var searchRule: SearchRule
    var bookInfoRule: BookInfoRule
    var chapterListRule: ChapterRule
    var contentRule: ContentRule
    
    // 高级设置
    var charset: String = "utf-8"
    var loginUrl: String?
    var cookies: String?
    var userAgent: String?
    var rateLimit: Int = 0 // 请求间隔(毫秒)
    
    // 规则优化
    var searchEncoding: String = "utf-8"
    var contentEncoding: String = "utf-8"
    var contentReplaceRules: [ReplaceRule] = []
    
    static func == (lhs: BookSource, rhs: BookSource) -> Bool {
        lhs.id == rhs.id
    }
}

struct SearchRule: Codable {
    var list: String       // 搜索结果列表规则
    var name: String       // 书名规则
    var author: String     // 作者规则
    var intro: String      // 简介规则
    var coverUrl: String   // 封面URL规则
    var bookUrl: String    // 书籍URL规则
    var lastChapter: String? // 最新章节规则
    var wordCount: String? // 字数规则
    var status: String?    // 状态规则
}

struct BookInfoRule: Codable {
    var name: String      // 书名规则
    var author: String    // 作者规则
    var cover: String     // 封面规则
    var intro: String     // 简介规则
    var lastChapter: String // 最新章节规则
    var catalog: String?  // 目录URL规则
    var status: String?   // 状态规则
    var updateTime: String? // 更新时间规则
    var wordCount: String? // 字数规则
    var category: String? // 分类规则
}

struct ChapterRule: Codable {
    var list: String      // 章节列表规则
    var name: String      // 章节名规则
    var url: String       // 章节URL规则
    var nextPage: String? // 下一页规则
    var updateTime: String? // 更新时间规则
    var isVip: String?    // VIP标识规则
}

struct ContentRule: Codable {
    var content: String   // 正文规则
    var next: String      // 下一页规则
    var title: String?    // 标题规则
    var ads: [String]     // 广告过滤规则
    var purify: [String]  // 净化规则
    
    init(content: String, next: String, title: String? = nil, ads: [String] = [], purify: [String] = []) {
        self.content = content
        self.next = next
        self.title = title
        self.ads = ads
        self.purify = purify
    }
}

struct ReplaceRule: Codable {
    var pattern: String
    var replacement: String
    var isRegex: Bool = false
} 