import Foundation
import SwiftSoup

class BookSourceParser {
    static let shared = BookSourceParser()
    
    private let networkManager = NetworkManager.shared
    private let cacheManager = CacheManager.shared
    
    // 搜索结果解析
    func parseSearchResults(html: String, rule: SearchRule, source: BookSource) throws -> [SearchResult] {
        let doc = try SwiftSoup.parse(html)
        let elements = try doc.select(rule.list)
        
        return try elements.compactMap { element in
            // 基本信息
            let title = try element.select(rule.name).text()
            let author = try element.select(rule.author).text()
            let intro = try element.select(rule.intro).text()
            
            // URL处理
            var bookUrl = try element.select(rule.bookUrl).attr("href")
            if !bookUrl.hasPrefix("http") {
                bookUrl = source.url + bookUrl
            }
            
            // 封面URL处理
            let rawCoverUrl = try? element.select(rule.coverUrl).attr("src")
            let finalCoverUrl = rawCoverUrl.map { url -> String in
                if !url.hasPrefix("http") {
                    return source.url + url
                }
                return url
            }
            
            return SearchResult(
                id: UUID(),
                title: title,
                author: author,
                coverUrl: finalCoverUrl,
                bookUrl: bookUrl,
                source: source,
                intro: intro
            )
        }
    }
    
    // 书籍详情解析
    func parseBookInfo(html: String, rule: BookInfoRule) throws -> BookInfo {
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.select(rule.name).text()
        let author = try doc.select(rule.author).text()
        let rawCoverUrl = try? doc.select(rule.cover).attr("src")
        let intro = try doc.select(rule.intro).text()
        let lastChapter = try doc.select(rule.lastChapter).text()
        
        return BookInfo(
            title: title,
            author: author,
            coverUrl: rawCoverUrl,
            intro: intro,
            lastChapter: lastChapter
        )
    }
    
    // 章节列表解析
    func parseChapterList(html: String, rule: ChapterRule) throws -> [Chapter] {
        let doc = try SwiftSoup.parse(html)
        let elements = try doc.select(rule.list)
        let baseUrl = doc.location()
        
        return try elements.compactMap { element in
            let title = try element.select(rule.name).text()
            var url = try element.select(rule.url).attr("href")
            
            // 处理相对URL
            if !url.hasPrefix("http"), let base = baseUrl {
                url = base + url
            }
            
            return Chapter(
                title: title,
                url: url
            )
        }
    }
    
    // 章节内容解析
    func parseContent(html: String, rule: ContentRule) throws -> String {
        let doc = try SwiftSoup.parse(html)
        var content = try doc.select(rule.content).text()
        
        // 移除广告
        for adRule in rule.ads {
            try doc.select(adRule).remove()
        }
        
        // 内容净化
        for purifyRule in rule.purify {
            content = content.replacingOccurrences(of: purifyRule, with: "", options: .regularExpression)
        }
        
        return content
    }
    
    // 处理分页内容
    func parseNextPageUrl(html: String, rule: String) throws -> String? {
        let doc = try SwiftSoup.parse(html)
        let nextUrl = try doc.select(rule).attr("href")
        return nextUrl.isEmpty ? nil : nextUrl
    }
} 