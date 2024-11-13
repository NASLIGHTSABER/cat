import SwiftUI

struct SearchView: View {
    @StateObject private var searchManager = BookSearchManager(sourceManager: BookSourceManager())
    @StateObject private var historyManager = SearchHistoryManager.shared
    @State private var searchText = ""
    @State private var showingHistory = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            SearchBar(text: $searchText) {
                performSearch()
            }
            
            if showingHistory && searchText.isEmpty {
                // 搜索历史
                List {
                    Section(header: Text("搜索历史")) {
                        ForEach(historyManager.history, id: \.self) { keyword in
                            HStack {
                                Text(keyword)
                                Spacer()
                                Button(action: {
                                    historyManager.removeItem(keyword)
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                searchText = keyword
                                performSearch()
                            }
                        }
                        
                        if !historyManager.history.isEmpty {
                            Button("清除历史记录") {
                                historyManager.clearHistory()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            } else {
                // 搜索结果
                if searchManager.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchManager.searchResults) { result in
                        NavigationLink(destination: BookDetailView(book: result.toBook())) {
                            SearchResultRow(result: result)
                        }
                    }
                }
            }
        }
        .navigationTitle("搜索")
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        showingHistory = false
        historyManager.addSearch(searchText)
        
        Task {
            await searchManager.search(keyword: searchText)
        }
    }
}

extension SearchResult {
    func toBook() -> Book {
        Book(
            title: title,
            author: author,
            coverUrl: coverUrl,
            lastReadChapter: "",
            lastReadTime: Date()
        )
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    
    var body: some View {
        HStack {
            TextField("搜索书籍", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit(onSearch)
            
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
            }
        }
        .padding()
    }
} 