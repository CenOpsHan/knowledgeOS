import SwiftUI

struct GlobalSearchView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.textTertiary)
                    TextField("Search your knowledge base...", text: $viewModel.query)
                        .font(.body)
                        .onChange(of: viewModel.query) { _ in viewModel.performSearch() }
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding()
                .background(Theme.surfaceElevated)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if viewModel.query.count < 2 {
                            Text("Search your knowledge base")
                                .foregroundColor(Theme.textTertiary)
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            if !viewModel.bookResults.isEmpty {
                                section("Books", icon: "book") {
                                    ForEach(viewModel.bookResults) { book in
                                        NavigationLink(destination: BookDetailView(book: book)) {
                                            HStack(spacing: 12) {
                                                if let url = book.coverUrl, let imgUrl = URL(string: url) {
                                                    AsyncImage(url: imgUrl) { image in
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } placeholder: { Color.gray.opacity(0.3) }
                                                    .frame(width: 32, height: 48)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                                }
                                                VStack(alignment: .leading) {
                                                    Text(book.title)
                                                        .font(.subheadline)
                                                        .foregroundColor(Theme.textPrimary)
                                                    Text(book.authors.joined(separator: ", "))
                                                        .font(.caption)
                                                        .foregroundColor(Theme.textSecondary)
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                            }

                            if !viewModel.extractResults.isEmpty {
                                section("Extracts", icon: "quote.opening") {
                                    ForEach(viewModel.extractResults) { extract in
                                        NavigationLink(destination: ExtractDetailView(extract: extract, bookId: extract.bookId)) {
                                            Text(extract.content.prefix(150))
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(Theme.textPrimary)
                                                .lineLimit(2)
                                                .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            if !viewModel.synthesisResults.isEmpty {
                                section("Syntheses", icon: "lightbulb") {
                                    ForEach(viewModel.synthesisResults) { synthesis in
                                        NavigationLink(destination: SynthesisDetailView(synthesis: synthesis, bookId: synthesis.bookId)) {
                                            VStack(alignment: .leading) {
                                                Text(synthesis.title)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(Theme.textPrimary)
                                                Text(synthesis.content.prefix(100))
                                                    .font(.caption)
                                                    .foregroundColor(Theme.textSecondary)
                                                    .lineLimit(1)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            if !viewModel.skillResults.isEmpty {
                                section("Skills", icon: "star") {
                                    ForEach(viewModel.skillResults) { skill in
                                        NavigationLink(destination: SkillDetailView(skill: skill)) {
                                            HStack(spacing: 8) {
                                                Text(skill.icon)
                                                Text(skill.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(Theme.textPrimary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            let total = viewModel.bookResults.count + viewModel.extractResults.count + viewModel.synthesisResults.count + viewModel.skillResults.count
                            if total == 0 {
                                Text("No results for \"\(viewModel.query)\"")
                                    .foregroundColor(Theme.textTertiary)
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Theme.bg)
        }
        .onAppear {
            if let userId = authService.userId {
                viewModel.subscribe(userId: userId)
            }
        }
        .onDisappear { viewModel.unsubscribe() }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textTertiary)
                    .textCase(.uppercase)
            }
            content()
        }
    }
}
