import SwiftUI
import MarkdownUI

struct AddSynthesisView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let bookId: String

    @State private var title = ""
    @State private var content = ""
    @State private var pageReferences = ""
    @State private var tags: [String] = []
    @State private var isSaving = false
    @State private var showPreview = false

    private let firestoreService = FirestoreService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Give this takeaway a title...", text: $title)
                        .font(.title3.weight(.semibold))
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(Theme.inputRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 0.5))

                    // Markdown editor
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            ForEach(["**B**", "_I_", "## H2", "- List"], id: \.self) { format in
                                Button {
                                    insertFormat(format)
                                } label: {
                                    Text(format.replacingOccurrences(of: "*", with: "").replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces))
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.surfaceHover)
                                        .cornerRadius(4)
                                }
                            }
                            Spacer()
                            Button(showPreview ? "Edit" : "Preview") {
                                showPreview.toggle()
                            }
                            .font(.caption.weight(.medium))
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.5))

                        if showPreview {
                            Markdown(content)
                                .markdownTheme(.gitHub)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                        } else {
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                    }
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 0.5))

                    TextField("e.g. Ch. 4, pp. 88-102", text: $pageReferences)
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(Theme.inputRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 0.5))

                    if let userId = authService.userId {
                        TagInputView(selectedTags: $tags, userId: userId)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("New Synthesis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func insertFormat(_ format: String) {
        content += format + " "
    }

    private func save() {
        guard let userId = authService.userId else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            let synthesis = Synthesis(
                bookId: bookId,
                title: title.trimmingCharacters(in: .whitespaces),
                content: content,
                pageReferences: pageReferences.isEmpty ? nil : pageReferences,
                tags: tags
            )
            _ = try? await firestoreService.createSynthesis(userId: userId, synthesis: synthesis)
            dismiss()
        }
    }
}
