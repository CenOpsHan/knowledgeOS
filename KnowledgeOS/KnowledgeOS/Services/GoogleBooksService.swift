import Foundation

struct GoogleBookResult: Identifiable {
    let id: String
    let title: String
    let authors: [String]
    let coverUrl: String?
    let pageCount: Int?
    let publisher: String?
    let publishedDate: String?
    let isbn: String?
}

class GoogleBooksService {
    private let googleBaseURL = "https://www.googleapis.com/books/v1/volumes"
    private let apiKey = "AIzaSyAc_oI24I5nFEqQR1TxMSXfXbwrraVXLwk"

    func search(query: String) async throws -> [GoogleBookResult] {
        guard query.count >= 3 else { return [] }

        // Try Google Books first
        if let results = try? await searchGoogle(query: query), !results.isEmpty {
            return results
        }

        // Fallback to Open Library
        return try await searchOpenLibrary(query: query)
    }

    private func searchGoogle(query: String) async throws -> [GoogleBookResult] {
        var components = URLComponents(string: googleBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "8"),
            URLQueryItem(name: "key", value: apiKey),
        ]

        guard let url = components.url else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return (decoded.items ?? []).map { item in
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

    private func searchOpenLibrary(query: String) async throws -> [GoogleBookResult] {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,number_of_pages_median,publisher,first_publish_year,isbn"),
        ]

        guard let url = components.url else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)

        return decoded.docs.map { doc in
            let coverId = doc.cover_i
            let coverUrl = coverId.map { "https://covers.openlibrary.org/b/id/\($0)-M.jpg" }

            return GoogleBookResult(
                id: doc.key,
                title: doc.title,
                authors: doc.author_name ?? [],
                coverUrl: coverUrl,
                pageCount: doc.number_of_pages_median,
                publisher: doc.publisher?.first,
                publishedDate: doc.first_publish_year.map(String.init),
                isbn: doc.isbn?.first
            )
        }
    }
}

// MARK: - Google Books Response Models

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

// MARK: - Open Library Response Models

private struct OpenLibraryResponse: Codable {
    let docs: [OpenLibraryDoc]
}

private struct OpenLibraryDoc: Codable {
    let key: String
    let title: String
    let author_name: [String]?
    let cover_i: Int?
    let number_of_pages_median: Int?
    let publisher: [String]?
    let first_publish_year: Int?
    let isbn: [String]?
}
