import Foundation
import FirebaseFirestore

@MainActor
class BookDetailViewModel: ObservableObject {
    @Published var book: Book?
    @Published var extracts: [Extract] = []
    @Published var syntheses: [Synthesis] = []
    @Published var isLoading = true

    private let firestoreService = FirestoreService()
    private var extractsListener: ListenerRegistration?
    private var synthesesListener: ListenerRegistration?

    func subscribe(userId: String, bookId: String) {
        extractsListener?.remove()
        synthesesListener?.remove()

        extractsListener = firestoreService.subscribeExtracts(userId: userId, bookId: bookId) { [weak self] items in
            self?.extracts = items
        }

        synthesesListener = firestoreService.subscribeSyntheses(userId: userId, bookId: bookId) { [weak self] items in
            self?.syntheses = items
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        extractsListener?.remove()
        synthesesListener?.remove()
    }

    func updateBook(userId: String, bookId: String, data: [String: Any]) async {
        try? await firestoreService.updateBook(userId: userId, bookId: bookId, data: data)
    }

    func deleteBook(userId: String, bookId: String) async {
        try? await firestoreService.deleteBook(userId: userId, bookId: bookId)
    }

    func deleteExtract(userId: String, extractId: String, bookId: String) async {
        try? await firestoreService.deleteExtract(userId: userId, extractId: extractId, bookId: bookId)
    }

    func deleteSynthesis(userId: String, synthesisId: String, bookId: String) async {
        try? await firestoreService.deleteSynthesis(userId: userId, synthesisId: synthesisId, bookId: bookId)
    }
}
