import SwiftUI

struct BookSourceManageView: View {
    @StateObject private var sourceManager = BookSourceManager()
    @State private var showingImport = false
    @State private var showingEdit = false
    @State private var selectedSource: BookSource?
    
    var body: some View {
        List {
            ForEach(sourceManager.sources) { source in
                HStack {
                    VStack(alignment: .leading) {
                        Text(source.name)
                            .font(.headline)
                        Text(source.url)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { source.enabled },
                        set: { enabled in
                            sourceManager.updateSourceStatus(source, enabled: enabled)
                        }
                    ))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSource = source
                    showingEdit = true
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        sourceManager.removeSource(source)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("书源管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingImport = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingImport) {
            BookSourceImportView(sourceManager: sourceManager)
        }
        .sheet(item: $selectedSource) { source in
            BookSourceEditView(source: source, sourceManager: sourceManager)
        }
    }
} 