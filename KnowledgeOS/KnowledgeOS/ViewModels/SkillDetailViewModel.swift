import Foundation

@MainActor
class SkillDetailViewModel: ObservableObject {
    @Published var skill: Skill?
    @Published var isEditing = false
    @Published var editName = ""
    @Published var editDescription = ""
    @Published var editIcon = "📚"
    @Published var editSections: [SkillSection] = []

    private let firestoreService = FirestoreService()

    func loadSkill(_ skill: Skill) {
        self.skill = skill
        editName = skill.name
        editDescription = skill.description
        editIcon = skill.icon
        editSections = skill.sections
    }

    func save(userId: String, skillId: String) async {
        try? await firestoreService.updateSkill(userId: userId, skillId: skillId, data: [
            "name": editName,
            "description": editDescription,
            "icon": editIcon,
            "sections": editSections.enumerated().map { index, section in
                [
                    "id": section.id,
                    "title": section.title,
                    "content": section.content,
                    "linkedExtractIds": section.linkedExtractIds,
                    "linkedSynthesisIds": section.linkedSynthesisIds,
                    "order": index,
                ] as [String: Any]
            },
        ])
        skill?.name = editName
        skill?.description = editDescription
        skill?.icon = editIcon
        skill?.sections = editSections
        isEditing = false
    }

    func addSection() {
        editSections.append(SkillSection(order: editSections.count))
    }

    func removeSection(at index: Int) {
        guard editSections.count > 1 else { return }
        editSections.remove(at: index)
    }
}
