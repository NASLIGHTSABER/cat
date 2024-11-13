import SwiftUI

struct ReaderView: View {
    let book: Book
    @State private var content: String = ""
    @State private var fontSize: CGFloat = 18
    @State private var brightness: CGFloat = UIScreen.main.brightness
    @State private var showingSettings = false
    @State private var currentChapter: Chapter?
    @State private var chapters: [Chapter] = []
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var showingChapterList = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    HStack(spacing: 0) {
                        // 左侧点击区域
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width * 0.3)
                            .onTapGesture {
                                previousPage()
                            }
                        
                        // 中间点击区域
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width * 0.4)
                            .onTapGesture {
                                showingSettings.toggle()
                            }
                        
                        // 右侧点击区域
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width * 0.3)
                            .onTapGesture {
                                nextPage()
                            }
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if let chapter = currentChapter {
                                Text(chapter.title)
                                    .font(.headline)
                                    .padding(.bottom)
                            }
                            
                            Text(content)
                                .font(.system(size: fontSize))
                        }
                        .padding()
                    }
                    .scrollDisabled(true)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingChapterList = true }) {
                    Image(systemName: "list.bullet")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ReaderSettings(fontSize: $fontSize, brightness: $brightness)
        }
        .sheet(isPresented: $showingChapterList) {
            ChapterListView(chapters: chapters, currentChapter: currentChapter) { chapter in
                loadChapter(chapter)
            }
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
                if let firstChapter = chapters.first {
                    await loadChapter(firstChapter)
                }
            } catch {
                print("Error loading chapters: \(error)")
            }
            isLoading = false
        }
    }
    
    private func loadChapter(_ chapter: Chapter) {
        Task {
            do {
                currentChapter = chapter
                // 实现章节内容加载逻辑
                calculatePages()
                currentPage = 0
            } catch {
                print("Error loading chapter: \(error)")
            }
        }
    }
    
    private func calculatePages() {
        // 计算总页数
        // 这里需要根据实际内容和显示区域计算
    }
    
    private func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        } else if let currentIndex = chapters.firstIndex(where: { $0.id == currentChapter?.id }),
                  currentIndex < chapters.count - 1 {
            loadChapter(chapters[currentIndex + 1])
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        } else if let currentIndex = chapters.firstIndex(where: { $0.id == currentChapter?.id }),
                  currentIndex > 0 {
            loadChapter(chapters[currentIndex - 1])
        }
    }
}

struct Chapter: Identifiable {
    let id = UUID()
    let title: String
    let url: String
}

struct ReaderSettings: View {
    @Binding var fontSize: CGFloat
    @Binding var brightness: CGFloat
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("字体大小")) {
                    Slider(value: $fontSize, in: 12...24, step: 1)
                }
                
                Section(header: Text("亮度")) {
                    Slider(value: $brightness, in: 0...1)
                        .onChange(of: brightness) { newValue in
                            UIScreen.main.brightness = newValue
                        }
                }
            }
            .navigationTitle("阅读设置")
        }
    }
} 