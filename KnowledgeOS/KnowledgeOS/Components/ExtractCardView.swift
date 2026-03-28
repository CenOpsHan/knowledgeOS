import SwiftUI

struct ExtractCardView: View {
    let extract: Extract

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(Theme.extract)
                Text(extract.content)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(3)
            }

            HStack {
                if let page = extract.pageNumber {
                    Text("p. \(page)")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceElevated)
                        .foregroundColor(Theme.textSecondary)
                        .clipShape(Capsule())
                } else if let range = extract.pageRange {
                    Text("pp. \(range)")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceElevated)
                        .foregroundColor(Theme.textSecondary)
                        .clipShape(Capsule())
                }

                ForEach(extract.tags.prefix(3), id: \.self) { tag in
                    TagPillView(name: tag)
                }

                Spacer()
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.extractDim)
        .overlay(
            Rectangle().fill(Theme.extract).frame(width: 3),
            alignment: .leading
        )
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }
}
