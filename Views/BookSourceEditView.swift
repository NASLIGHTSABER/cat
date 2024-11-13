import SwiftUI

struct BookSourceEditView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var sourceManager: BookSourceManager
    @State private var source: BookSource
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    
    init(source: BookSource? = nil, sourceManager: BookSourceManager) {
        self.sourceManager = sourceManager
        _source = State(initialValue: source ?? BookSource(
            name: "",
            url: "",
            searchUrl: "",
            searchRule: SearchRule(list: "", name: "", author: "", intro: "", coverUrl: "", bookUrl: ""),
            bookInfoRule: BookInfoRule(name: "", author: "", cover: "", intro: "", lastChapter: ""),
            chapterListRule: ChapterRule(list: "", name: "", url: ""),
            contentRule: ContentRule(content: "", next: "")
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("书源名称", text: $source.name)
                    TextField("书源URL", text: $source.url)
                    TextField("搜索URL", text: $source.searchUrl)
                }
                
                Section(header: Text("搜索规则")) {
                    TextField("列表规则", text: $source.searchRule.list)
                    TextField("书名规则", text: $source.searchRule.name)
                    TextField("作者规则", text: $source.searchRule.author)
                    TextField("简介规则", text: $source.searchRule.intro)
                    TextField("封面规则", text: $source.searchRule.coverUrl)
                    TextField("书籍URL规则", text: $source.searchRule.bookUrl)
                }
                
                Section(header: Text("书籍信息规则")) {
                    TextField("书名规则", text: $source.bookInfoRule.name)
                    TextField("作者规则", text: $source.bookInfoRule.author)
                    TextField("封面规则", text: $source.bookInfoRule.cover)
                    TextField("简介规则", text: $source.bookInfoRule.intro)
                    TextField("最新章节规则", text: $source.bookInfoRule.lastChapter)
                }
                
                Section(header: Text("章节规则")) {
                    TextField("目录���则", text: $source.chapterListRule.list)
                    TextField("章节名规则", text: $source.chapterListRule.name)
                    TextField("章节URL规则", text: $source.chapterListRule.url)
                }
                
                Section(header: Text("正文规则")) {
                    TextField("正文规则", text: $source.contentRule.content)
                    TextField("下一页规则", text: $source.contentRule.next)
                }
            }
            .navigationTitle(source.name.isEmpty ? "新建书源" : "编辑书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSource()
                    }
                }
            }
            .alert("提示", isPresented: $showingSaveAlert) {
                Button("确定", role: .cancel) {
                    if alertMessage == "保存成功" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveSource() {
        // 验证必填字段
        guard !source.name.isEmpty, !source.url.isEmpty, !source.searchUrl.isEmpty else {
            alertMessage = "请填写必要的信息"
            showingSaveAlert = true
            return
        }
        
        sourceManager.addSource(source)
        alertMessage = "保存成功"
        showingSaveAlert = true
    }
} 