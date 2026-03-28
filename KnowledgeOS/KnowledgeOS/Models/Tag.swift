import Foundation
import FirebaseFirestore

struct Tag: Codable, Identifiable {
    var id: String { name }
    var name: String
    var color: String
    @ServerTimestamp var dateCreated: Timestamp?

    enum CodingKeys: String, CodingKey {
        case color, dateCreated
    }

    init(name: String, color: String) {
        self.name = name
        self.color = color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = "" // Will be set from documentID in FirestoreService
        self.color = try container.decode(String.self, forKey: .color)
        self.dateCreated = try container.decodeIfPresent(Timestamp.self, forKey: .dateCreated)
    }
}
