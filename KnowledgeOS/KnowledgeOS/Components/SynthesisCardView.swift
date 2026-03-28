import SwiftUI

struct SynthesisCardView: View {
    let synthesis: Synthesis

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb")
                    .font(.caption)
                    .foregroundColor(Theme.synthesis)
                VStack(alignment: .leading, spacing: 4) {
                    Text(synthesis.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(synthesis.content.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "*", with: ""))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(3)
                }
            }

            if let refs = synthesis.pageReferences {
                Text(refs)
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
            }

            HStack {
                ForEach(synthesis.tags.prefix(3), id: \.self) { tag in
                    TagPillView(name: tag)
                }
                Spacer()
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.synthesisDim)
        .overlay(
            Rectangle().fill(Theme.synthesis).frame(width: 3),
            alignment: .leading
        )
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }
}
