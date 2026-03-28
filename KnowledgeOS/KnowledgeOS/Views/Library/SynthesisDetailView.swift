import SwiftUI
import MarkdownUI

struct SynthesisDetailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let synthesis: Synthesis
    let bookId: String

    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editPageRefs = ""
    @State private var showDelete = false

    private let firestoreService = FirestoreService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("SYNTHESIS")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.synthesis.opacity(0.2))
                    .foregroundColor(Theme.synthesis)
                    .clipShape(Capsule())

                if isEditing {
                    TextField("Title", text: $editTitle)
                        .font(.title2.bold())
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(Theme.inputRadius)

                    TextEditor(text: $editContent)
                        .font(.body)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        .padding()
                        .background(Color.white.opacity(0.4))
                        .cornerRadius(Theme.inputRadius)

                    TextField("Page references", text: $editPageRefs)
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(Theme.inputRadius)
                } else {
                    Text(synthesis.title)
                        .font(.title2.bold())

                    if let refs = synthesis.pageReferences {
                        Text(refs)
                            .font(.subheadline)
                            .foregroundColor(Theme.textTertiary)
                    }

                    VStack(alignment: .leading) {
                        Markdown(synthesis.content)
                            .markdownTheme(.gitHub)
                    }
                    .padding()
                    .background(Theme.synthesisDim)
                    .overlay(
                        Rectangle().fill(Theme.synthesis).frame(width: 3),
                        alignment: .leading
                    )
                    .cornerRadius(Theme.inputRadius)
                }

                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                    if synthesis.tags.isEmpty {
                        Text("No tags")
                            .font(.caption)
                            .foregroundColor(Theme.textTertiary)
                    } else {
                        FlowLayout(spacing: 6) {
                            ForEach(synthesis.tags, id: \.self) { tag in
                                TagPillView(name: tag)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
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
        .alert("Delete Synthesis?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { deleteSynthesis() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func startEditing() {
        editTitle = synthesis.title
        editContent = synthesis.content
        editPageRefs = synthesis.pageReferences ?? ""
        isEditing = true
    }

    private func saveEdits() {
        guard let userId = authService.userId, let id = synthesis.id else { return }
        Task {
            try? await firestoreService.updateSynthesis(userId: userId, synthesisId: id, data: [
                "title": editTitle,
                "content": editContent,
                "pageReferences": editPageRefs.isEmpty ? NSNull() : editPageRefs,
            ])
            isEditing = false
        }
    }

    private func deleteSynthesis() {
        guard let userId = authService.userId, let id = synthesis.id else { return }
        Task {
            try? await firestoreService.deleteSynthesis(userId: userId, synthesisId: id, bookId: bookId)
            dismiss()
        }
    }
}
