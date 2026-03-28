import SwiftUI

struct AddBookView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AddBookViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.textTertiary)
                            TextField("Search by title, author, or ISBN...", text: $viewModel.searchQuery)
                                .textFieldStyle(.plain)
                                .onChange(of: viewModel.searchQuery) { _ in viewModel.search() }
                        }
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(Theme.inputRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.inputRadius)
                                .stroke(Theme.border, lineWidth: 1)
                        )

                        if !viewModel.searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(viewModel.searchResults) { result in
                                    Button { viewModel.selectResult(result) } label: {
                                        HStack(spacing: 12) {
                                            if let url = result.coverUrl, let imgUrl = URL(string: url) {
                                                AsyncImage(url: imgUrl) { image in
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } placeholder: { Color.gray.opacity(0.3) }
                                                .frame(width: 40, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                            }
                                            VStack(alignment: .leading) {
                                                Text(result.title)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundColor(Theme.textPrimary)
                                                Text(result.authors.joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundColor(Theme.textSecondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                    }
                                    Divider().background(Theme.border)
                                }
                            }
                            .background(Theme.surfaceElevated)
                            .cornerRadius(Theme.cardRadius)
                        }
                    }

                    // Cover preview
                    if let coverUrl = viewModel.coverUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: { ProgressView() }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Form
                    Group {
                        formField("Title *", text: $viewModel.title)
                        formField("Author(s)", text: $viewModel.authors, placeholder: "Comma-separated")
                        HStack(spacing: 12) {
                            formField("Pages", text: $viewModel.pageCount)
                            formField("ISBN", text: Binding(
                                get: { viewModel.isbn ?? "" },
                                set: { viewModel.isbn = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        formField("Publisher", text: $viewModel.publisher)
                    }

                    // Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        Picker("Status", selection: $viewModel.status) {
                            Text("Reading").tag("reading")
                            Text("Completed").tag("completed")
                            Text("Shelved").tag("shelved")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Save button
                    Button {
                        guard let userId = authService.userId else { return }
                        Task {
                            _ = try? await viewModel.save(userId: userId)
                            dismiss()
                        }
                    } label: {
                        Text(viewModel.isSaving ? "Adding..." : "Add to Library")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.accent.opacity(0.5) : Theme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(Theme.inputRadius)
                    }
                    .disabled(viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSaving)
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func formField(_ label: String, text: Binding<String>, placeholder: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            TextField(placeholder ?? label, text: text)
                .padding()
                .background(Theme.surface)
                .cornerRadius(Theme.inputRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.inputRadius)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
    }
}
