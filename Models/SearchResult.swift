import Foundation
import SwiftUI

struct SearchResult: Identifiable {
    var id = UUID()
    let title: String
    let author: String
    let coverUrl: String?
    let bookUrl: String
    let source: BookSource
    let intro: String
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack {
            if let coverUrl = result.coverUrl {
                AsyncImage(url: URL(string: coverUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 80)
                .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                Text(result.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(result.intro)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
} 