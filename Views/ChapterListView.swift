import SwiftUI

struct ChapterListView: View {
    let chapters: [Chapter]
    let currentChapter: Chapter?
    let onSelect: (Chapter) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(chapters) { chapter in
                Button(action: {
                    onSelect(chapter)
                    dismiss()
                }) {
                    Text(chapter.title)
                        .foregroundColor(.primary)
                }
            }
            .navigationTitle("目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
} 