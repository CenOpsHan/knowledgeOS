import Foundation
import FirebaseFirestore

struct SkillSection: Codable, Identifiable {
    var id: String
    var title: String
    var content: String
    var linkedExtractIds: [String]
    var linkedSynthesisIds: [String]
    var order: Int

    init(title: String = "", content: String = "", order: Int = 0) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.linkedExtractIds = []
        self.linkedSynthesisIds = []
        self.order = order
    }
}

struct Skill: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var icon: String
    var sections: [SkillSection]
    @ServerTimestamp var dateCreated: Timestamp?
    @ServerTimestamp var dateModified: Timestamp?

    init(
        name: String,
        description: String = "",
        icon: String = "📚",
        sections: [SkillSection] = [SkillSection()]
    ) {
        self.name = name
        self.description = description
        self.icon = icon
        self.sections = sections
    }
}
