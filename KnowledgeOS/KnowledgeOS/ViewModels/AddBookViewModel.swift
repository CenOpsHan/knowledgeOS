import Foundation

@MainActor
class AddBookViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [GoogleBookResult] = []
    @Published var isSearching = false
    @Published var title = ""
    @Published var authors = ""
    @Published var coverUrl: String?
    @Published var isbn: String?
    @Published var pageCount = ""
    @Published var publisher = ""
    @Published var publishedDate = ""
    @Published var googleBooksId: String?
    @Published var status = "reading"
    @Published var isSaving = false

    private let googleBooksService = GoogleBooksService()
    private let firestoreService = FirestoreService()
    private var searchTask: Task<Void, Never>?

    @Published var searchError: String?

    func search() {
        searchTask?.cancel()
        guard searchQuery.count >= 3 else {
            searchResults = []
            searchError = nil
            return
        }
        isSearching = true
        searchError = nil
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            do {
                let results = try await googleBooksService.search(query: searchQuery)
                if !Task.isCancelled {
                    searchResults = results
                    searchError = results.isEmpty ? "No results found" : nil
                }
            } catch {
                if !Task.isCancelled {
                    searchError = "Search failed: \(error.localizedDescription)"
                }
            }
            isSearching = false
        }
    }

    func selectResult(_ result: GoogleBookResult) {
        title = result.title
        authors = result.authors.joined(separator: ", ")
        coverUrl = result.coverUrl
        isbn = result.isbn
        pageCount = result.pageCount.map(String.init) ?? ""
        publisher = result.publisher ?? ""
        publishedDate = result.publishedDate ?? ""
        googleBooksId = result.id
        searchResults = []
        searchQuery = ""
    }

    func save(userId: String) async throws -> String {
        isSaving = true
        defer { isSaving = false }

        let book = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            authors: authors.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            coverUrl: coverUrl,
            isbn: isbn,
            pageCount: Int(pageCount),
            publisher: publisher.isEmpty ? nil : publisher,
            publishedDate: publishedDate.isEmpty ? nil : publishedDate,
            googleBooksId: googleBooksId,
            status: status
        )

        return try await firestoreService.createBook(userId: userId, book: book)
    }
}
