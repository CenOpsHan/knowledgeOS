import Foundation
import FirebaseFirestore

struct Tag: Codable, Identifiable {
    var id: String { name }
    var name: String
    var color: String
    @ServerTimestamp var dateCreated: Timestamp?

    init(name: String, color: String) {
        self.name = name
        self.color = color
    }
}
