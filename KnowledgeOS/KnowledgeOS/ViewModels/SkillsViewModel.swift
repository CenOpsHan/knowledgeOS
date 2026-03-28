import Foundation
import FirebaseFirestore

@MainActor
class SkillsViewModel: ObservableObject {
    @Published var skills: [Skill] = []
    @Published var isLoading = true

    private let firestoreService = FirestoreService()
    private var listener: ListenerRegistration?

    func subscribe(userId: String) {
        listener?.remove()
        listener = firestoreService.subscribeSkills(userId: userId) { [weak self] items in
            self?.skills = items
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
    }

    func deleteSkill(userId: String, skillId: String) async {
        try? await firestoreService.deleteSkill(userId: userId, skillId: skillId)
    }
}
