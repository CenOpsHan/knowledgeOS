import Foundation
import FirebaseFirestore

struct Extract: Codable, Identifiable {
    @DocumentID var id: String?
    var bookId: String
    var content: String
    var pageNumber: Int?
    var pageRange: String?
    var chapter: String?
    var tags: [String]
    var linkedSkillIds: [String]
    var sourcePhotoPaths: [String]
    @ServerTimestamp var dateCreated: Timestamp?
    @ServerTimestamp var dateModified: Timestamp?

    init(
        bookId: String,
        content: String,
        pageNumber: Int? = nil,
        pageRange: String? = nil,
        chapter: String? = nil,
        tags: [String] = [],
        sourcePhotoPaths: [String] = []
    ) {
        self.bookId = bookId
        self.content = content
        self.pageNumber = pageNumber
        self.pageRange = pageRange
        self.chapter = chapter
        self.tags = tags
        self.linkedSkillIds = []
        self.sourcePhotoPaths = sourcePhotoPaths
    }
}
