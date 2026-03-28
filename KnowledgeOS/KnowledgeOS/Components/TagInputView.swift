import SwiftUI
import FirebaseFirestore

struct TagInputView: View {
    @Binding var selectedTags: [String]
    let userId: String

    @State private var inputText = ""
    @State private var allTags: [Tag] = []
    @State private var showSuggestions = false
    private let firestoreService = FirestoreService()
    private var listener: ListenerRegistration?

    var suggestions: [Tag] {
        guard !inputText.isEmpty else { return [] }
        let q = inputText.lowercased()
        return allTags.filter {
            $0.name.lowercased().contains(q) && !selectedTags.contains($0.name)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)

            // Selected tags
            if !selectedTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(selectedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                            Button {
                                selectedTags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.15))
                        .foregroundColor(Theme.accent)
                        .clipShape(Capsule())
                    }
                }
            }

            // Input field
            HStack {
                TextField("Add tag...", text: $inputText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { addTag(inputText) }

                if !inputText.isEmpty {
                    Button {
                        addTag(inputText)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .padding(10)
            .background(Theme.surface)
            .cornerRadius(Theme.inputRadius)
            .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

            // Suggestions
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { tag in
                        Button {
                            addTag(tag.name)
                        } label: {
                            Text(tag.name)
                                .font(.subheadline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }
                .background(Theme.surfaceElevated)
                .cornerRadius(Theme.inputRadius)
                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))
            }
        }
        .task {
            loadTags()
        }
    }

    private func addTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !selectedTags.contains(trimmed) else {
            inputText = ""
            return
        }
        selectedTags.append(trimmed)
        inputText = ""

        // Auto-create tag in Firestore if it doesn't exist
        if !allTags.contains(where: { $0.name == trimmed }) {
            let palette = Theme.tagColors
            let color = palette[selectedTags.count % palette.count]
            Task {
                try? await firestoreService.createTag(userId: userId, name: trimmed, color: color)
            }
        }
    }

    private func loadTags() {
        _ = firestoreService.subscribeTags(userId: userId) { tags in
            allTags = tags
        }
    }
}
