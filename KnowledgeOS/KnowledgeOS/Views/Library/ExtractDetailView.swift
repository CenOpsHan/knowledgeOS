import SwiftUI

struct ExtractDetailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let extract: Extract
    let bookId: String

    @State private var isEditing = false
    @State private var editContent: String = ""
    @State private var editPageNumber: String = ""
    @State private var editPageRange: String = ""
    @State private var editChapter: String = ""
    @State private var showDelete = false
    @State private var photoURLs: [URL] = []

    private let firestoreService = FirestoreService()
    private let storageService = StorageService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Type badge
                Text("VERBATIM")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.extract.opacity(0.2))
                    .foregroundColor(Theme.extract)
                    .clipShape(Capsule())

                // Page info
                if let page = extract.pageNumber {
                    Text("Page \(page)")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                } else if let range = extract.pageRange {
                    Text("Pages \(range)")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                // Content
                VStack(alignment: .leading) {
                    Text("\u{201C}")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.extract.opacity(0.3))

                    if isEditing {
                        TextEditor(text: $editContent)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                    } else {
                        Text(extract.content)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding()
                .background(Theme.extractDim)
                .overlay(
                    Rectangle().fill(Theme.extract).frame(width: 3),
                    alignment: .leading
                )
                .cornerRadius(Theme.inputRadius)

                // Source photos
                if !photoURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Photos")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photoURLs, id: \.absoluteString) { url in
                                    AsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: { ProgressView() }
                                    .frame(width: 150, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }

                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                    if extract.tags.isEmpty {
                        Text("No tags")
                            .font(.caption)
                            .foregroundColor(Theme.textTertiary)
                    } else {
                        FlowLayout(spacing: 6) {
                            ForEach(extract.tags, id: \.self) { tag in
                                TagPillView(name: tag)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") { saveEdits() }
                } else {
                    Menu {
                        Button { startEditing() } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .alert("Delete Extract?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { deleteExtract() }
            Button("Cancel", role: .cancel) {}
        }
        .task {
            if !extract.sourcePhotoPaths.isEmpty {
                photoURLs = await storageService.getDownloadURLs(paths: extract.sourcePhotoPaths)
            }
        }
    }

    private func startEditing() {
        editContent = extract.content
        editPageNumber = extract.pageNumber.map(String.init) ?? ""
        editPageRange = extract.pageRange ?? ""
        editChapter = extract.chapter ?? ""
        isEditing = true
    }

    private func saveEdits() {
        guard let userId = authService.userId, let extractId = extract.id else { return }
        Task {
            try? await firestoreService.updateExtract(userId: userId, extractId: extractId, data: [
                "content": editContent,
                "pageNumber": Int(editPageNumber) as Any,
                "pageRange": editPageRange.isEmpty ? NSNull() : editPageRange,
                "chapter": editChapter.isEmpty ? NSNull() : editChapter,
            ])
            isEditing = false
        }
    }

    private func deleteExtract() {
        guard let userId = authService.userId, let extractId = extract.id else { return }
        Task {
            try? await firestoreService.deleteExtract(userId: userId, extractId: extractId, bookId: bookId)
            dismiss()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowMaxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowMaxHeight + spacing
                rowMaxHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowMaxHeight = max(rowMaxHeight, size.height)
            maxHeight = max(maxHeight, y + size.height)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}
