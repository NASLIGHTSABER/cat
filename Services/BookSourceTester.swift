import Foundation

class BookSourceTester {
    static let shared = BookSourceTester()
    
    func testSource(_ source: BookSource) async throws -> TestResult {
        var results = [TestStep: Bool]()
        
        // 测试搜索
        do {
            let searchUrl = source.searchUrl.replacingOccurrences(of: "{keyword}", with: "测试")
            guard let url = URL(string: searchUrl) else {
                throw TestError.invalidURL
            }
            
            let html = try await NetworkManager.shared.fetchHTML(url)
            let searchResults = try BookSourceParser.shared.parseSearchResults(html: html, rule: source.searchRule, source: source)
            results[.search] = !searchResults.isEmpty
            
            // 如果搜索成功，测试书籍详情
            if let firstBook = searchResults.first {
                guard let bookUrl = URL(string: firstBook.bookUrl) else {
                    throw TestError.invalidURL
                }
                
                let bookHtml = try await NetworkManager.shared.fetchHTML(bookUrl)
                let bookInfo = try BookSourceParser.shared.parseBookInfo(html: bookHtml, rule: source.bookInfoRule)
                results[.bookInfo] = true
                
                // 测试章节列表
                let chapters = try BookSourceParser.shared.parseChapterList(html: bookHtml, rule: source.chapterListRule)
                results[.chapterList] = !chapters.isEmpty
                
                // 测试章节内容
                if let firstChapter = chapters.first,
                   let chapterUrl = URL(string: firstChapter.url) {
                    let chapterHtml = try await NetworkManager.shared.fetchHTML(chapterUrl)
                    let content = try BookSourceParser.shared.parseContent(html: chapterHtml, rule: source.contentRule)
                    results[.content] = !content.isEmpty
                }
            }
        } catch {
            print("Test error: \(error)")
        }
        
        return TestResult(steps: results)
    }
}

enum TestStep {
    case search
    case bookInfo
    case chapterList
    case content
}

struct TestResult {
    let steps: [TestStep: Bool]
    
    var isSuccessful: Bool {
        steps.values.allSatisfy { $0 }
    }
}

enum TestError: Error {
    case invalidURL
    case parseError
} 