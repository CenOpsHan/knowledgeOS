import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = BookDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    let book: Book
    @State private var selectedTab = 0
    @State private var showDelete = false
    @State private var showCaptureExtract = false
    @State private var showAddSynthesis = false
    @State private var noteExpanded = false
    @State private var personalNote: String = ""
    @State private var noteSaveTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                heroSection

                // Personal Note
                noteSection

                // Stats
                statsRow

                // Tab bar
                tabBar

                // Tab content
                if selectedTab == 0 {
                    extractsTab
                } else {
                    synthesesTab
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Menu("Status") {
                        Button { updateStatus("reading") } label: {
                            Label("Reading", systemImage: book.status == "reading" ? "checkmark" : "book")
                        }
                        Button { updateStatus("completed") } label: {
                            Label("Completed", systemImage: book.status == "completed" ? "checkmark" : "checkmark.circle")
                        }
                        Button { updateStatus("shelved") } label: {
                            Label("Shelved", systemImage: book.status == "shelved" ? "checkmark" : "bookmark")
                        }
                    }
                    Button(role: .destructive) { showDelete = true } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Delete \(book.title)?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                guard let userId = authService.userId, let bookId = book.id else { return }
                Task {
                    await viewModel.deleteBook(userId: userId, bookId: bookId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all \(book.verbatimCount) extracts and \(book.synthesisCount) syntheses.")
        }
        .sheet(isPresented: $showCaptureExtract) {
            CaptureExtractView(bookId: book.id ?? "")
                .environmentObject(authService)
        }
        .sheet(isPresented: $showAddSynthesis) {
            AddSynthesisView(bookId: book.id ?? "")
                .environmentObject(authService)
        }
        .onAppear {
            personalNote = book.personalNote ?? ""
            if let userId = authService.userId, let bookId = book.id {
                viewModel.subscribe(userId: userId, bookId: bookId)
            }
        }
        .onDisappear {
            viewModel.unsubscribe()
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 12) {
            if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { ProgressView() }
                .frame(width: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 8)
            }

            Text(book.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(book.authors.joined(separator: ", "))
                .foregroundColor(Theme.textSecondary)

            if let publisher = book.publisher {
                Text({
                    var parts: [String] = [publisher]
                    if let date = book.publishedDate {
                        parts.append(String(date.prefix(4)))
                    }
                    if let count = book.pageCount {
                        parts.append("\(count) pages")
                    }
                    return parts.joined(separator: " · ")
                }())
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
            }

            // Rating
            StarRatingView(rating: book.rating ?? 0) { newRating in
                guard let userId = authService.userId, let bookId = book.id else { return }
                Task {
                    await viewModel.updateBook(userId: userId, bookId: bookId, data: ["rating": newRating])
                }
            }
        }
    }

    // MARK: - Note
    private var noteSection: some View {
        VStack(alignment: .leading) {
            Button { noteExpanded.toggle() } label: {
                HStack {
                    Text("Personal Note")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Image(systemName: noteExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.textTertiary)
                }
            }

            if noteExpanded {
                TextEditor(text: $personalNote)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.4))
                    .cornerRadius(Theme.inputRadius)
                    .onChange(of: personalNote) { newValue in
                        noteSaveTask?.cancel()
                        noteSaveTask = Task {
                            try? await Task.sleep(nanoseconds: 800_000_000)
                            guard !Task.isCancelled else { return }
                            guard let userId = authService.userId, let bookId = book.id else { return }
                            await viewModel.updateBook(userId: userId, bookId: bookId, data: ["personalNote": newValue])
                        }
                    }
            }
        }
        .padding(Theme.cardPadding)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 0.5))
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(icon: "book", color: Theme.extract, count: book.verbatimCount, label: "Extracts")
            statCard(icon: "lightbulb", color: Theme.synthesis, count: book.synthesisCount, label: "Syntheses")
            statCard(icon: "tag", color: Theme.skill, count: uniqueTagCount, label: "Tags")
        }
    }

    private func statCard(icon: String, color: Color, count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(count)")
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 0.5))
    }

    private var uniqueTagCount: Int {
        Set(viewModel.extracts.flatMap(\.tags) + viewModel.syntheses.flatMap(\.tags)).count
    }

    // MARK: - Tabs
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("Extracts", color: Theme.extract, isSelected: selectedTab == 0) { selectedTab = 0 }
            tabButton("Syntheses", color: Theme.synthesis, isSelected: selectedTab == 1) { selectedTab = 1 }
        }
    }

    private func tabButton(_ title: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? color : Theme.textTertiary)
                Rectangle()
                    .fill(isSelected ? color : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Extracts Tab
    private var extractsTab: some View {
        VStack(spacing: 12) {
            Button { showCaptureExtract = true } label: {
                Label("Capture Extract", systemImage: "camera")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.extract)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.extract.opacity(0.1))
                    .cornerRadius(Theme.cardRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .stroke(Theme.extract.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    )
            }

            if viewModel.extracts.isEmpty {
                Text("No extracts yet. Capture your first passage.")
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(viewModel.extracts) { extract in
                    NavigationLink(destination: ExtractDetailView(extract: extract, bookId: book.id ?? "")) {
                        ExtractCardView(extract: extract)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Syntheses Tab
    private var synthesesTab: some View {
        VStack(spacing: 12) {
            Button { showAddSynthesis = true } label: {
                Label("Add Synthesis", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.synthesis)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.synthesis.opacity(0.1))
                    .cornerRadius(Theme.cardRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .stroke(Theme.synthesis.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    )
            }

            if viewModel.syntheses.isEmpty {
                Text("No syntheses yet. Write your first takeaway.")
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(viewModel.syntheses) { synthesis in
                    NavigationLink(destination: SynthesisDetailView(synthesis: synthesis, bookId: book.id ?? "")) {
                        SynthesisCardView(synthesis: synthesis)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func updateStatus(_ status: String) {
        guard let userId = authService.userId, let bookId = book.id else { return }
        Task {
            await viewModel.updateBook(userId: userId, bookId: bookId, data: ["status": status])
        }
    }
}
