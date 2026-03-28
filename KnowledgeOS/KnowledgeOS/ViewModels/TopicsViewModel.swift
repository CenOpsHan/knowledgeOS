import Foundation
import FirebaseFirestore

@MainActor
class TopicsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var isLoading = true

    private let firestoreService = FirestoreService()
    private var listener: ListenerRegistration?

    func subscribe(userId: String) {
        listener?.remove()
        listener = firestoreService.subscribeTags(userId: userId) { [weak self] items in
            self?.tags = items
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
    }

    func deleteTag(userId: String, tagName: String) async {
        try? await firestoreService.deleteTag(userId: userId, tagName: tagName)
    }
}
