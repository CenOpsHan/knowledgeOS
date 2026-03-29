import SwiftUI

/// Renders a book cover with 3D mockup effects: spine edge, page edges, and shadow
struct BookCoverView: View {
    let coverContent: AnyView
    var width: CGFloat = .infinity
    var fixedAspectRatio: CGFloat? = 2.0/3.0

    private let spineWidth: CGFloat = 6
    private let pageEdgeWidth: CGFloat = 4

    var body: some View {
        HStack(spacing: 0) {
            // Spine edge (left side of the book)
            LinearGradient(
                colors: [.black.opacity(0.3), .black.opacity(0.05), .black.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: spineWidth)

            // Main cover
            ZStack(alignment: .leading) {
                coverContent

                // Spine fold highlight/shadow on cover
                LinearGradient(
                    colors: [
                        .black.opacity(0.2),
                        .black.opacity(0.05),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 12)

                // Subtle light reflection near spine
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.08),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
                .offset(x: 10)
            }

            // Page edges (right side)
            VStack(spacing: 0) {
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0
                              ? Color(white: 0.92)
                              : Color(white: 0.96))
                }
            }
            .frame(width: pageEdgeWidth)
            .overlay(
                // Top/bottom shadow on page edges
                LinearGradient(
                    colors: [.black.opacity(0.08), .clear, .clear, .black.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .modifier(OptionalAspectRatio(ratio: fixedAspectRatio))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 1,
                bottomLeadingRadius: 1,
                bottomTrailingRadius: 2,
                topTrailingRadius: 2
            )
        )
        // Book shadow: heavier on right and bottom (like sitting on shelf)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 5, y: 6)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 2, y: 2)
        // Subtle bottom edge shadow for depth
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 3)
    }
}

extension BookCoverView {
    init<Content: View>(width: CGFloat = .infinity, fixedAspectRatio: CGFloat? = 2.0/3.0, @ViewBuilder content: () -> Content) {
        self.coverContent = AnyView(content())
        self.width = width
        self.fixedAspectRatio = fixedAspectRatio
    }
}

private struct OptionalAspectRatio: ViewModifier {
    let ratio: CGFloat?
    func body(content: Content) -> some View {
        if let ratio {
            content.aspectRatio(ratio, contentMode: .fit)
        } else {
            content
        }
    }
}
