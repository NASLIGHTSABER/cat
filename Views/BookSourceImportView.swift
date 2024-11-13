import SwiftUI
import UniformTypeIdentifiers

struct BookSourceImportView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var sourceManager: BookSourceManager
    @State private var showingFilePicker = false
    @State private var showingUrlInput = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var urlString = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("从文件导入") {
                        showingFilePicker = true
                    }
                    Button("从剪贴板导入") {
                        importFromClipboard()
                    }
                    Button("从URL导入") {
                        showingUrlInput = true
                    }
                }
                
                Section {
                    Button("导入默认书源") {
                        importDefaultSources()
                    }
                }
            }
            .navigationTitle("导入书源")
            .navigationBarItems(trailing: Button("完成") { dismiss() })
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    importSourceFiles(urls)
                case .failure(let error):
                    alertMessage = "选择文件失败：\(error.localizedDescription)"
                    showingAlert = true
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingUrlInput) {
                NavigationView {
                    Form {
                        Section(header: Text("输入URL")) {
                            TextField("https://example.com/sources.json", text: $urlString)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            
                            Button("从剪贴板粘贴") {
                                if let pasteboardString = UIPasteboard.general.string {
                                    urlString = pasteboardString.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            }
                        }
                        
                        Section {
                            Button("导入") {
                                importFromUrl()
                            }
                            .disabled(urlString.isEmpty)
                        }
                    }
                    .navigationTitle("从URL导入")
                    .navigationBarItems(trailing: Button("取消") {
                        urlString = ""
                        showingUrlInput = false
                    })
                }
            }
        }
    }
    
    private func importSourceFiles(_ urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                alertMessage = "无法访问选择的文件"
                showingAlert = true
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                guard !data.isEmpty else {
                    alertMessage = "文件内容为空"
                    showingAlert = true
                    continue
                }
                
                let sources = try JSONDecoder().decode([BookSource].self, from: data)
                if sources.isEmpty {
                    alertMessage = "未找到有效的书源"
                    showingAlert = true
                    continue
                }
                
                sources.forEach { sourceManager.addSource($0) }
                alertMessage = "成功导入 \(sources.count) 个书源"
            } catch let error as DecodingError {
                switch error {
                case .dataCorrupted:
                    alertMessage = "书源格式错误"
                case .keyNotFound(let key, _):
                    alertMessage = "缺少必要字段：\(key.stringValue)"
                case .typeMismatch(_, let context):
                    alertMessage = "数据类型不匹配：\(context.debugDescription)"
                case .valueNotFound(_, let context):
                    alertMessage = "缺少必要数据：\(context.debugDescription)"
                @unknown default:
                    alertMessage = "解析失败：\(error.localizedDescription)"
                }
            } catch {
                alertMessage = "导入失败：\(error.localizedDescription)"
            }
            showingAlert = true
        }
    }
    
    private func importFromClipboard() {
        guard let string = UIPasteboard.general.string,
              !string.isEmpty else {
            alertMessage = "剪贴板为空"
            showingAlert = true
            return
        }
        
        guard let data = string.data(using: .utf8) else {
            alertMessage = "剪贴板内容无法解析"
            showingAlert = true
            return
        }
        
        do {
            let sources = try JSONDecoder().decode([BookSource].self, from: data)
            if sources.isEmpty {
                alertMessage = "未找到有效的书源"
                showingAlert = true
                return
            }
            
            sources.forEach { sourceManager.addSource($0) }
            alertMessage = "成功导入 \(sources.count) 个书源"
        } catch let error as DecodingError {
            switch error {
            case .dataCorrupted:
                alertMessage = "书源格式错误"
            case .keyNotFound(let key, _):
                alertMessage = "缺少必要字段：\(key.stringValue)"
            case .typeMismatch(_, let context):
                alertMessage = "数据类型不匹配：\(context.debugDescription)"
            case .valueNotFound(_, let context):
                alertMessage = "缺少必要数据：\(context.debugDescription)"
            @unknown default:
                alertMessage = "解析失败：\(error.localizedDescription)"
            }
        } catch {
            alertMessage = "导入失败：\(error.localizedDescription)"
        }
        showingAlert = true
    }
    
    private func importFromUrl() {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            alertMessage = "无效的URL"
            showingAlert = true
            return
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard !data.isEmpty else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "返回数据为空"])
                    }
                    
                    let sources = try JSONDecoder().decode([BookSource].self, from: data)
                    if sources.isEmpty {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到有效的书源"])
                    }
                    
                    await MainActor.run {
                        sources.forEach { sourceManager.addSource($0) }
                        alertMessage = "成功导入 \(sources.count) 个书源"
                        urlString = ""
                        showingUrlInput = false
                    }
                    
                case 301, 302, 303, 307, 308:
                    // 处理重定向
                    if let newURLString = httpResponse.value(forHTTPHeaderField: "Location"),
                       let newURL = URL(string: newURLString) {
                        urlString = newURL.absoluteString
                        importFromUrl()
                    } else {
                        throw NetworkError.invalidRedirect
                    }
                    
                default:
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
            } catch let error as NSError {
                await MainActor.run {
                    if error.domain == NSURLErrorDomain && error.code == -1200 {
                        alertMessage = "SSL证书验证失败，请检查网站是否支持HTTPS或证书是否有效"
                    } else {
                        alertMessage = "导入失败：\(error.localizedDescription)"
                    }
                }
            }
            await MainActor.run {
                showingAlert = true
            }
        }
    }
    
    private func importDefaultSources() {
        let defaultSources: [BookSource] = [
            BookSource(
                name: "笔趣阁",
                url: "https://www.biquge.com",
                searchUrl: "https://www.biquge.com/search.php?keyword={keyword}",
                searchRule: SearchRule(
                    list: ".result-list .result-item",
                    name: ".result-game-item-title a",
                    author: ".result-game-item-info p:nth-child(1)",
                    intro: ".result-game-item-desc",
                    coverUrl: ".result-game-item-pic img",
                    bookUrl: ".result-game-item-title a"
                ),
                bookInfoRule: BookInfoRule(
                    name: "#info h1",
                    author: "#info p:nth-child(1)",
                    cover: "#fmimg img",
                    intro: "#intro",
                    lastChapter: "#info p:last-child"
                ),
                chapterListRule: ChapterRule(
                    list: "#list dd",
                    name: "a",
                    url: "a"
                ),
                contentRule: ContentRule(
                    content: "#content",
                    next: ".bottem2 a:last-child"
                )
            ),
            // 可以添加更多默认书源
        ]
        
        if defaultSources.isEmpty {
            alertMessage = "暂无默认书源"
        } else {
            defaultSources.forEach { sourceManager.addSource($0) }
            alertMessage = "成功导入 \(defaultSources.count) 个默认书源"
        }
        showingAlert = true
    }
} 