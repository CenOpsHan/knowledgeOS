import Foundation

struct GoogleBookResult: Identifiable {
    let id: String // googleBooksId
    let title: String
    let authors: [String]
    let coverUrl: String?
    let pageCount: Int?
    let publisher: String?
    let publishedDate: String?
    let isbn: String?
}

class GoogleBooksService {
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    func search(query: String) async throws -> [GoogleBookResult] {
        guard query.count >= 3 else { return [] }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "8"),
        ]

        guard let url = components.url else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return (response.items ?? []).map { item in
            let v = item.volumeInfo
            let isbn = v.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
            let thumbnail = v.imageLinks?.thumbnail?.replacingOccurrences(of: "http:", with: "https:")

            return GoogleBookResult(
                id: item.id,
                title: v.title ?? "",
                authors: v.authors ?? [],
                coverUrl: thumbnail,
                pageCount: v.pageCount,
                publisher: v.publisher,
                publishedDate: v.publishedDate,
                isbn: isbn
            )
        }
    }
}

// MARK: - Response Models

private struct GoogleBooksResponse: Codable {
    let items: [GoogleBooksItem]?
}

private struct GoogleBooksItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

private struct VolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let imageLinks: ImageLinks?
    let pageCount: Int?
    let publisher: String?
    let publishedDate: String?
    let industryIdentifiers: [IndustryIdentifier]?
}

private struct ImageLinks: Codable {
    let thumbnail: String?
}

private struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}
