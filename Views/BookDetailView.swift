import SwiftUI

struct BookDetailView: View {
    let book: Book
    @State private var chapters: [Chapter] = []
    @State private var isLoading = false
    @State private var showingChapterList = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 书籍信息头部
                HStack(spacing: 16) {
                    if let coverUrl = book.coverUrl {
                        AsyncImage(url: URL(string: coverUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 120, height: 160)
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(book.author)
                            .foregroundColor(.gray)
                        Text("最后阅读：\(book.lastReadChapter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // 操作按钮
                HStack(spacing: 20) {
                    Button(action: startReading) {
                        Label("开始阅读", systemImage: "book")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { showingChapterList = true }) {
                        Label("目录", systemImage: "list.bullet")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingChapterList) {
            ChapterListView(
                chapters: chapters,
                currentChapter: nil,
                onSelect: { chapter in
                    // 处理章节选择
                    showingChapterList = false
                }
            )
        }
        .onAppear {
            loadChapters()
        }
    }
    
    private func loadChapters() {
        isLoading = true
        Task {
            do {
                // 实现章节加载逻辑
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func startReading() {
        // 实现开始阅读逻辑
    }
} 