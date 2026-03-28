import Foundation
import FirebaseFirestore

struct Book: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var authors: [String]
    var coverUrl: String?
    var coverStoragePath: String?
    var isbn: String?
    var pageCount: Int?
    var publisher: String?
    var publishedDate: String?
    var googleBooksId: String?
    var status: String // "reading", "completed", "shelved"
    var rating: Int?
    var personalNote: String?
    var verbatimCount: Int
    var synthesisCount: Int
    @ServerTimestamp var dateAdded: Timestamp?
    @ServerTimestamp var dateModified: Timestamp?

    init(
        title: String,
        authors: [String] = [],
        coverUrl: String? = nil,
        coverStoragePath: String? = nil,
        isbn: String? = nil,
        pageCount: Int? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        googleBooksId: String? = nil,
        status: String = "reading",
        rating: Int? = nil,
        personalNote: String? = nil
    ) {
        self.title = title
        self.authors = authors
        self.coverUrl = coverUrl
        self.coverStoragePath = coverStoragePath
        self.isbn = isbn
        self.pageCount = pageCount
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.googleBooksId = googleBooksId
        self.status = status
        self.rating = rating
        self.personalNote = personalNote
        self.verbatimCount = 0
        self.synthesisCount = 0
    }
}
