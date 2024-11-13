//
//  ContentView.swift
//  cat
//
//  Created by base64 ⁣ on 2024/11/10.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 书架页面
            BookshelfView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("书架")
                }
                .tag(0)
            
            // 我的页面
            MineView()
                .tabItem {
                    Image(systemName: "person")
                    Text("我的")
                }
                .tag(1)
        }
    }
}

// 书架视图
struct BookshelfView: View {
    @State private var books: [Book] = []
    @State private var isGridLayout = true
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isGridLayout {
                    BookGridView(books: books)
                } else {
                    BookListView(books: books)
                }
            }
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isGridLayout.toggle() }) {
                        Image(systemName: isGridLayout ? "list.bullet" : "square.grid.2x2")
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
        }
    }
}

// 我的视图
struct MineView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("设置")) {
                    NavigationLink(destination: BookSourceManageView()) {
                        Label("书源管理", systemImage: "doc.text")
                    }
                    NavigationLink(destination: Text("备份与恢复")) {
                        Label("备份与恢复", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                Section(header: Text("关于")) {
                    NavigationLink(destination: Text("关于应用")) {
                        Label("关于", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

// 网格视图
struct BookGridView: View {
    let books: [Book]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(books) { book in
                    BookGridItem(book: book)
                }
            }
            .padding()
        }
    }
}

// 列表视图
struct BookListView: View {
    let books: [Book]
    
    var body: some View {
        List(books) { book in
            BookListItem(book: book)
        }
    }
}

// 网格项目视图
struct BookGridItem: View {
    let book: Book
    
    var body: some View {
        VStack {
            if let coverUrl = book.coverUrl {
                AsyncImage(url: URL(string: coverUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 90, height: 120)
                .cornerRadius(5)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 90, height: 120)
                    .cornerRadius(5)
            }
            
            Text(book.title)
                .font(.caption)
                .lineLimit(2)
        }
    }
}

// 列表项目视图
struct BookListItem: View {
    let book: Book
    
    var body: some View {
        HStack {
            if let coverUrl = book.coverUrl {
                AsyncImage(url: URL(string: coverUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 45, height: 60)
                .cornerRadius(3)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 45, height: 60)
                    .cornerRadius(3)
            }
            
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(book.lastReadChapter)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
