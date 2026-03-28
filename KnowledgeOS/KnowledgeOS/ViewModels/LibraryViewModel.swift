import Foundation
import FirebaseFirestore

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = true
    @Published var statusFilter = "all"
    @Published var sortBy = "recent"

    private let firestoreService = FirestoreService()
    private var listener: ListenerRegistration?

    var filteredBooks: [Book] {
        var result = statusFilter == "all"
            ? books
            : books.filter { $0.status == statusFilter }

        switch sortBy {
        case "az":
            result.sort { ($0.title) < ($1.title) }
        case "rating":
            result.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        default:
            break
        }

        return result
    }

    func subscribe(userId: String) {
        listener?.remove()
        listener = firestoreService.subscribeBooks(userId: userId) { [weak self] books in
            self?.books = books
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
    }
}
