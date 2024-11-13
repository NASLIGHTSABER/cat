import Foundation
import ZIPFoundation

class EPUBParser {
    static func parse(url: URL) throws -> LocalBook {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // 解压EPUB文件
        try FileManager.default.unzipItem(at: url, to: tempDir)
        
        // 解析container.xml获取OPF文件路径
        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
        let containerXML = try String(contentsOf: containerURL)
        guard let opfPath = parseOPFPath(from: containerXML) else {
            throw LocalBookError.parseError
        }
        
        // 解析OPF文件
        let opfURL = tempDir.appendingPathComponent(opfPath)
        let opfXML = try String(contentsOf: opfURL)
        let bookInfo = try parseOPF(from: opfXML)
        
        // 解析章节内容
        let chapters = try parseChapters(from: opfXML, baseURL: opfURL.deletingLastPathComponent())
        
        return LocalBook(
            title: bookInfo.title,
            author: bookInfo.author,
            format: .epub,
            content: "", // EPUB不需要存储完整内容
            chapters: chapters
        )
    }
    
    private static func parseOPFPath(from containerXML: String) -> String? {
        // 简单的XML解析，实际应使用XMLParser
        let pattern = #"full-path="([^"]+)"#
        guard let match = containerXML.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        let path = String(containerXML[match])
            .replacingOccurrences(of: #"full-path=""#, with: "")
            .replacingOccurrences(of: #"""#, with: "")
        return path
    }
    
    private static func parseOPF(from opfXML: String) throws -> (title: String, author: String) {
        // 简单的XML解析，实际应使用XMLParser
        let titlePattern = #"<dc:title>([^<]+)</dc:title>"#
        let authorPattern = #"<dc:creator[^>]*>([^<]+)</dc:creator>"#
        
        guard let titleMatch = opfXML.range(of: titlePattern, options: .regularExpression),
              let authorMatch = opfXML.range(of: authorPattern, options: .regularExpression) else {
            throw LocalBookError.parseError
        }
        
        let title = String(opfXML[titleMatch])
            .replacingOccurrences(of: "<dc:title>", with: "")
            .replacingOccurrences(of: "</dc:title>", with: "")
        
        let author = String(opfXML[authorMatch])
            .replacingOccurrences(of: #"<dc:creator[^>]*>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "</dc:creator>", with: "")
        
        return (title, author)
    }
    
    private static func parseChapters(from opfXML: String, baseURL: URL) throws -> [LocalChapter] {
        var chapters: [LocalChapter] = []
        let spinePattern = #"<spine[^>]*>(.*?)</spine>"#
        let itemRefPattern = #"<itemref idref="([^"]+)""#
        let manifestPattern = #"<item id="([^"]+)" href="([^"]+)""#
        
        guard let spineMatch = opfXML.range(of: spinePattern, options: [.regularExpression, .caseInsensitive]) else {
            throw LocalBookError.parseError
        }
        
        let spine = String(opfXML[spineMatch])
        let itemRefs = spine.matches(for: itemRefPattern)
        let manifest = opfXML.matches(for: manifestPattern)
        
        for (index, itemRef) in itemRefs.enumerated() {
            guard let href = manifest.first(where: { $0.0 == itemRef.0 })?.1 else { continue }
            let chapterURL = baseURL.appendingPathComponent(href)
            let content = try String(contentsOf: chapterURL)
            
            chapters.append(LocalChapter(
                title: "Chapter \(index + 1)",
                content: content,
                startOffset: 0,
                endOffset: content.count
            ))
        }
        
        return chapters
    }
}

extension String {
    func matches(for pattern: String) -> [(String, String)] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        return matches.compactMap { match in
            guard match.numberOfRanges >= 3,
                  let id = Range(match.range(at: 1), in: self),
                  let href = Range(match.range(at: 2), in: self) else { return nil }
            return (String(self[id]), String(self[href]))
        }
    }
} 