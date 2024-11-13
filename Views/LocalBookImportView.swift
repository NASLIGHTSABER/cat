import SwiftUI
import UniformTypeIdentifiers

struct LocalBookImportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var importedBooks: [LocalBook] = []
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("导入本地文件") {
                        showingFilePicker = true
                    }
                }
                
                if !importedBooks.isEmpty {
                    Section("已导入的书籍") {
                        ForEach(importedBooks) { book in
                            HStack {
                                Text(book.title)
                                Spacer()
                                Text(book.format.rawValue)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("导入本地书籍")
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.plainText, UTType.epub],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    importBooks(urls)
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func importBooks(_ urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let book = try LocalBookParser.parse(url: url)
                importedBooks.append(book)
                try LocalBookManager.shared.saveBook(book)
                alertMessage = "导入成功"
            } catch {
                alertMessage = "导入失败：\(error.localizedDescription)"
            }
            showingAlert = true
        }
    }
}

struct LocalBook: Identifiable, Codable {
    let id = UUID()
    let title: String
    let author: String
    let format: BookFormat
    let content: String
    let chapters: [LocalChapter]
}

struct LocalChapter: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let startOffset: Int
    let endOffset: Int
}

enum BookFormat: String, Codable {
    case txt = "TXT"
    case epub = "EPUB"
} 