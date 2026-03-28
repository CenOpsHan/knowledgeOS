import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    private let storage = Storage.storage()

    func uploadPhoto(userId: String, bookId: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let filename = UUID().uuidString + ".jpg"
        let path = "users/\(userId)/photos/\(bookId)/\(filename)"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return path
    }

    func getDownloadURL(path: String) async throws -> URL {
        try await storage.reference().child(path).downloadURL()
    }

    func getDownloadURLs(paths: [String]) async -> [URL] {
        await withTaskGroup(of: URL?.self) { group in
            for path in paths {
                group.addTask {
                    try? await self.getDownloadURL(path: path)
                }
            }
            var urls: [URL] = []
            for await url in group {
                if let url { urls.append(url) }
            }
            return urls
        }
    }
}
