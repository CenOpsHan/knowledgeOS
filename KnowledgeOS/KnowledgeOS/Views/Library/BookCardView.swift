import SwiftUI

struct BookCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 3D book mockup cover
            BookCoverView {
                if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                    CachedAsyncImage(url: url) {
                        coverPlaceholder
                    }
                } else {
                    coverPlaceholder
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            // Title
            Text(book.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)

            // Author
            Text(book.authors.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)

            // Stats
            HStack {
                if book.verbatimCount > 0 {
                    Text("\(book.verbatimCount)")
                        .font(.caption2)
                        .foregroundColor(Theme.textTertiary)
                }
                Spacer()
                if let rating = book.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.star)
                        Text("\(rating)")
                            .font(.caption2)
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
        }
    }

    private var coverPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.accent.opacity(0.2), Theme.skill.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(String(book.title.prefix(1)))
                .font(.largeTitle.bold())
                .foregroundColor(Theme.textPrimary.opacity(0.6))
        }
    }
}
