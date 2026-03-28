import Foundation
import FirebaseFirestore

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var bookResults: [Book] = []
    @Published var extractResults: [Extract] = []
    @Published var synthesisResults: [Synthesis] = []
    @Published var skillResults: [Skill] = []

    private var allBooks: [Book] = []
    private var allExtracts: [Extract] = []
    private var allSyntheses: [Synthesis] = []
    private var allSkills: [Skill] = []

    private let firestoreService = FirestoreService()
    private var listeners: [ListenerRegistration] = []

    func subscribe(userId: String) {
        listeners.forEach { $0.remove() }
        listeners = []

        listeners.append(firestoreService.subscribeBooks(userId: userId) { [weak self] items in
            self?.allBooks = items
            self?.performSearch()
        })
        listeners.append(firestoreService.subscribeSkills(userId: userId) { [weak self] items in
            self?.allSkills = items
            self?.performSearch()
        })

        let db = Firestore.firestore()
        listeners.append(
            db.collection("users").document(userId).collection("extracts")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.allExtracts = snapshot?.documents.compactMap { try? $0.data(as: Extract.self) } ?? []
                    self?.performSearch()
                }
        )
        listeners.append(
            db.collection("users").document(userId).collection("syntheses")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.allSyntheses = snapshot?.documents.compactMap { try? $0.data(as: Synthesis.self) } ?? []
                    self?.performSearch()
                }
        )
    }

    func unsubscribe() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    func performSearch() {
        let q = query.lowercased()
        guard q.count >= 2 else {
            bookResults = []
            extractResults = []
            synthesisResults = []
            skillResults = []
            return
        }

        bookResults = allBooks.filter {
            $0.title.lowercased().contains(q) ||
            $0.authors.contains { $0.lowercased().contains(q) }
        }

        extractResults = allExtracts.filter {
            $0.content.lowercased().contains(q)
        }

        synthesisResults = allSyntheses.filter {
            $0.title.lowercased().contains(q) ||
            $0.content.lowercased().contains(q)
        }

        skillResults = allSkills.filter {
            $0.name.lowercased().contains(q) ||
            $0.sections.contains { $0.content.lowercased().contains(q) }
        }
    }
}
