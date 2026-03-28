import Foundation
import FirebaseFirestore

struct Synthesis: Codable, Identifiable {
    @DocumentID var id: String?
    var bookId: String
    var title: String
    var content: String
    var pageReferences: String?
    var tags: [String]
    var linkedSkillIds: [String]
    @ServerTimestamp var dateCreated: Timestamp?
    @ServerTimestamp var dateModified: Timestamp?

    init(
        bookId: String,
        title: String,
        content: String = "",
        pageReferences: String? = nil,
        tags: [String] = []
    ) {
        self.bookId = bookId
        self.title = title
        self.content = content
        self.pageReferences = pageReferences
        self.tags = tags
        self.linkedSkillIds = []
    }
}
