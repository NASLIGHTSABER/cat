import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let cacheManager = CacheManager.shared
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 100*1024*1024, diskCapacity: 300*1024*1024)
        
        session = URLSession(configuration: config)
    }
    
    func fetch<T: Decodable>(_ url: URL, headers: [String: String]? = nil) async throws -> T {
        var request = URLRequest(url: url)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(T.self, from: data)
        case 301, 302, 303, 307, 308:
            guard let location = httpResponse.value(forHTTPHeaderField: "Location"),
                  let redirectUrl = URL(string: location) else {
                throw NetworkError.invalidRedirect
            }
            return try await fetch(redirectUrl, headers: headers)
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func fetchHTML(_ url: URL, source: BookSource? = nil) async throws -> String {
        var request = URLRequest(url: url)
        
        // 添加来源特定的请求头
        if let source = source {
            source.header?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            if let userAgent = source.userAgent {
                request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            }
            if let cookies = source.cookies {
                request.setValue(cookies, forHTTPHeaderField: "Cookie")
            }
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            // 处理编码
            let encoding = source?.contentEncoding ?? "utf-8"
            if let html = String(data: data, encoding: .utf8) {
                return html
            }
            
            // 尝试使用指定的编码
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encoding as CFString)
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
            if nsEncoding != kCFStringEncodingInvalidId,
               let html = String(data: data, encoding: String.Encoding(rawValue: nsEncoding)) {
                return html
            }
            
            throw NetworkError.invalidData
            
        case 301, 302, 303, 307, 308:
            guard let location = httpResponse.value(forHTTPHeaderField: "Location"),
                  let redirectUrl = URL(string: location) else {
                throw NetworkError.invalidRedirect
            }
            return try await fetchHTML(redirectUrl, source: source)
            
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func downloadImage(_ url: URL) async throws -> Data {
        // 检查缓存
        if let cachedData = cacheManager.getImage(for: url) {
            return cachedData
        }
        
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        // 缓存图片
        cacheManager.cacheImage(data, for: url)
        return data
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case invalidRedirect
    case httpError(Int)
    case sslError
    case rateLimited
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .invalidData:
            return "数据格式错误"
        case .invalidRedirect:
            return "重定向错误"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .sslError:
            return "SSL连接错误，请检查网络设置或网站证书"
        case .rateLimited:
            return "请求过于频繁，请稍后再试"
        case .timeout:
            return "请求超时，请检查网络连接"
        }
    }
} 