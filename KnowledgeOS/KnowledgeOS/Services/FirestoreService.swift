import Foundation
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    private func userCol(_ userId: String, _ collection: String) -> CollectionReference {
        db.collection("users").document(userId).collection(collection)
    }

    private func userDoc(_ userId: String, _ collection: String, _ docId: String) -> DocumentReference {
        db.collection("users").document(userId).collection(collection).document(docId)
    }

    private enum BatchOp {
        case delete(DocumentReference)
        case update(DocumentReference, [String: Any])
        case set(DocumentReference, [String: Any])
    }

    private func commitInChunks(_ ops: [BatchOp]) async throws {
        let chunkSize = 499
        for i in stride(from: 0, to: ops.count, by: chunkSize) {
            let chunk = ops[i..<min(i + chunkSize, ops.count)]
            let batch = db.batch()
            for op in chunk {
                switch op {
                case .delete(let ref): batch.deleteDocument(ref)
                case .update(let ref, let data): batch.updateData(data, forDocument: ref)
                case .set(let ref, let data): batch.setData(data, forDocument: ref)
                }
            }
            try await batch.commit()
        }
    }

    // MARK: - Books

    func subscribeBooks(userId: String, completion: @escaping ([Book]) -> Void) -> ListenerRegistration {
        userCol(userId, "books")
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { snapshot, _ in
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                DispatchQueue.main.async { completion(books) }
            }
    }

    func createBook(userId: String, book: Book) async throws -> String {
        var data = try Firestore.Encoder().encode(book)
        data["verbatimCount"] = 0
        data["synthesisCount"] = 0
        data["dateAdded"] = FieldValue.serverTimestamp()
        data["dateModified"] = FieldValue.serverTimestamp()
        let ref = try await userCol(userId, "books").addDocument(data: data)
        return ref.documentID
    }

    func updateBook(userId: String, bookId: String, data: [String: Any]) async throws {
        var data = data
        data["dateModified"] = FieldValue.serverTimestamp()
        try await userDoc(userId, "books", bookId).updateData(data)
    }

    func deleteBook(userId: String, bookId: String) async throws {
        var ops: [BatchOp] = [.delete(userDoc(userId, "books", bookId))]

        let extracts = try await userCol(userId, "extracts")
            .whereField("bookId", isEqualTo: bookId).getDocuments()
        extracts.documents.forEach { ops.append(.delete($0.reference)) }

        let syntheses = try await userCol(userId, "syntheses")
            .whereField("bookId", isEqualTo: bookId).getDocuments()
        syntheses.documents.forEach { ops.append(.delete($0.reference)) }

        try await commitInChunks(ops)
    }

    // MARK: - Extracts

    func subscribeExtracts(userId: String, bookId: String, completion: @escaping ([Extract]) -> Void) -> ListenerRegistration {
        userCol(userId, "extracts")
            .whereField("bookId", isEqualTo: bookId)
            .order(by: "dateCreated", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Extract.self) } ?? []
                DispatchQueue.main.async { completion(items) }
            }
    }

    func createExtract(userId: String, extract: Extract) async throws -> String {
        let batch = db.batch()
        let ref = userCol(userId, "extracts").document()
        var data = try Firestore.Encoder().encode(extract)
        data["dateCreated"] = FieldValue.serverTimestamp()
        data["dateModified"] = FieldValue.serverTimestamp()
        batch.setData(data, forDocument: ref)
        batch.updateData([
            "verbatimCount": FieldValue.increment(Int64(1)),
            "dateModified": FieldValue.serverTimestamp()
        ], forDocument: userDoc(userId, "books", extract.bookId))
        try await batch.commit()
        return ref.documentID
    }

    func updateExtract(userId: String, extractId: String, data: [String: Any]) async throws {
        var data = data
        data["dateModified"] = FieldValue.serverTimestamp()
        try await userDoc(userId, "extracts", extractId).updateData(data)
    }

    func deleteExtract(userId: String, extractId: String, bookId: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(userDoc(userId, "extracts", extractId))
        batch.updateData([
            "verbatimCount": FieldValue.increment(Int64(-1)),
            "dateModified": FieldValue.serverTimestamp()
        ], forDocument: userDoc(userId, "books", bookId))
        try await batch.commit()
    }

    // MARK: - Syntheses

    func subscribeSyntheses(userId: String, bookId: String, completion: @escaping ([Synthesis]) -> Void) -> ListenerRegistration {
        userCol(userId, "syntheses")
            .whereField("bookId", isEqualTo: bookId)
            .order(by: "dateCreated", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Synthesis.self) } ?? []
                DispatchQueue.main.async { completion(items) }
            }
    }

    func createSynthesis(userId: String, synthesis: Synthesis) async throws -> String {
        let batch = db.batch()
        let ref = userCol(userId, "syntheses").document()
        var data = try Firestore.Encoder().encode(synthesis)
        data["dateCreated"] = FieldValue.serverTimestamp()
        data["dateModified"] = FieldValue.serverTimestamp()
        batch.setData(data, forDocument: ref)
        batch.updateData([
            "synthesisCount": FieldValue.increment(Int64(1)),
            "dateModified": FieldValue.serverTimestamp()
        ], forDocument: userDoc(userId, "books", synthesis.bookId))
        try await batch.commit()
        return ref.documentID
    }

    func updateSynthesis(userId: String, synthesisId: String, data: [String: Any]) async throws {
        var data = data
        data["dateModified"] = FieldValue.serverTimestamp()
        try await userDoc(userId, "syntheses", synthesisId).updateData(data)
    }

    func deleteSynthesis(userId: String, synthesisId: String, bookId: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(userDoc(userId, "syntheses", synthesisId))
        batch.updateData([
            "synthesisCount": FieldValue.increment(Int64(-1)),
            "dateModified": FieldValue.serverTimestamp()
        ], forDocument: userDoc(userId, "books", bookId))
        try await batch.commit()
    }

    // MARK: - Skills

    func subscribeSkills(userId: String, completion: @escaping ([Skill]) -> Void) -> ListenerRegistration {
        userCol(userId, "skills")
            .order(by: "dateCreated", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Skill.self) } ?? []
                DispatchQueue.main.async { completion(items) }
            }
    }

    func createSkill(userId: String, skill: Skill) async throws -> String {
        var data = try Firestore.Encoder().encode(skill)
        data["dateCreated"] = FieldValue.serverTimestamp()
        data["dateModified"] = FieldValue.serverTimestamp()
        let ref = try await userCol(userId, "skills").addDocument(data: data)
        return ref.documentID
    }

    func updateSkill(userId: String, skillId: String, data: [String: Any]) async throws {
        var data = data
        data["dateModified"] = FieldValue.serverTimestamp()
        try await userDoc(userId, "skills", skillId).updateData(data)
    }

    func deleteSkill(userId: String, skillId: String) async throws {
        try await userDoc(userId, "skills", skillId).delete()
    }

    // MARK: - Tags

    func subscribeTags(userId: String, completion: @escaping ([Tag]) -> Void) -> ListenerRegistration {
        userCol(userId, "tags").addSnapshotListener { snapshot, _ in
            let items = snapshot?.documents.compactMap { doc -> Tag? in
                var tag = try? doc.data(as: Tag.self)
                tag?.name = doc.documentID
                return tag
            } ?? []
            DispatchQueue.main.async { completion(items) }
        }
    }

    func createTag(userId: String, name: String, color: String) async throws {
        try await userDoc(userId, "tags", name.lowercased()).setData([
            "color": color,
            "dateCreated": FieldValue.serverTimestamp()
        ])
    }

    func deleteTag(userId: String, tagName: String) async throws {
        var ops: [BatchOp] = [.delete(userDoc(userId, "tags", tagName))]

        let extracts = try await userCol(userId, "extracts")
            .whereField("tags", arrayContains: tagName).getDocuments()
        for doc in extracts.documents {
            var tags = (doc.data()["tags"] as? [String]) ?? []
            tags.removeAll { $0 == tagName }
            ops.append(.update(doc.reference, ["tags": tags]))
        }

        let syntheses = try await userCol(userId, "syntheses")
            .whereField("tags", arrayContains: tagName).getDocuments()
        for doc in syntheses.documents {
            var tags = (doc.data()["tags"] as? [String]) ?? []
            tags.removeAll { $0 == tagName }
            ops.append(.update(doc.reference, ["tags": tags]))
        }

        try await commitInChunks(ops)
    }
}
