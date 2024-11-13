import Foundation

class LocalBookParser {
    static func parse(url: URL) throws -> LocalBook {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "txt":
            return try parseTxt(url: url)
        case "epub":
            return try parseEpub(url: url)
        default:
            throw LocalBookError.unsupportedFormat
        }
    }
    
    private static func parseTxt(url: URL) throws -> LocalBook {
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = url.deletingPathExtension().lastPathComponent
        let chapters = try parseChapters(from: content)
        
        return LocalBook(
            title: title,
            author: "未知",
            format: .txt,
            content: content,
            chapters: chapters
        )
    }
    
    private static func parseEpub(url: URL) throws -> LocalBook {
        // 实现EPUB解析
        throw LocalBookError.unsupportedFormat
    }
    
    private static func parseChapters(from content: String) throws -> [LocalChapter] {
        var chapters: [LocalChapter] = []
        let pattern = "第[0-9一二三四五六七八九十百千]+[章节卷集].*"
        let regex = try NSRegularExpression(pattern: pattern)
        let nsString = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
        
        for i in 0..<matches.count {
            let currentMatch = matches[i]
            let startOffset = currentMatch.range.location
            let endOffset = i < matches.count - 1 ? matches[i + 1].range.location : nsString.length
            let title = nsString.substring(with: currentMatch.range)
            let chapterContent = nsString.substring(with: NSRange(location: startOffset, length: endOffset - startOffset))
            
            chapters.append(LocalChapter(
                title: title,
                content: chapterContent,
                startOffset: startOffset,
                endOffset: endOffset
            ))
        }
        
        return chapters
    }
}

enum LocalBookError: Error {
    case unsupportedFormat
    case parseError
} 