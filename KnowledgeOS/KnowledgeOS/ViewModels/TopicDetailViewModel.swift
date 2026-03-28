import Foundation
import FirebaseFirestore

@MainActor
class TopicDetailViewModel: ObservableObject {
    @Published var extracts: [Extract] = []
    @Published var syntheses: [Synthesis] = []
    @Published var isLoading = true

    private let firestoreService = FirestoreService()
    private var extractsListener: ListenerRegistration?
    private var synthesesListener: ListenerRegistration?

    func subscribe(userId: String, tagName: String) {
        // Note: Firestore array-contains queries used here
        // We load all extracts/syntheses and filter client-side for the tag
        extractsListener?.remove()
        synthesesListener?.remove()

        let db = Firestore.firestore()

        extractsListener = db.collection("users").document(userId).collection("extracts")
            .whereField("tags", arrayContains: tagName)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.extracts = snapshot?.documents.compactMap { try? $0.data(as: Extract.self) } ?? []
            }

        synthesesListener = db.collection("users").document(userId).collection("syntheses")
            .whereField("tags", arrayContains: tagName)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.syntheses = snapshot?.documents.compactMap { try? $0.data(as: Synthesis.self) } ?? []
                self?.isLoading = false
            }
    }

    func unsubscribe() {
        extractsListener?.remove()
        synthesesListener?.remove()
    }
}
