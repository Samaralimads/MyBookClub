//
//  BookSearchService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

enum BookSearchField: String, CaseIterable {
    case title  = "Title"
    case author = "Author"
    case isbn   = "ISBN"
}

@Observable
final class BookSearchService {

    var results: [Book] = []
    var isLoading = false
    var error: AppError?

    // MARK: - Public

    func search(query: String, field: BookSearchField) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let effectiveQuery: String
        switch field {
        case .isbn:
            let digits = trimmed.filter { $0.isNumber || $0 == "X" || $0 == "x" }
            guard digits.count >= 10 else {
                results = []
                return
            }
            effectiveQuery = digits
        case .title, .author:
            guard trimmed.count >= 3 else {
                results = []
                return
            }
            effectiveQuery = trimmed
        }

        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            results = try await fetchBooks(query: effectiveQuery, field: field)
        } catch {
            if (error as NSError).code == NSURLErrorCancelled { return }
            self.error = AppError(underlying: error)
            results = []
        }
    }

    // MARK: - Routing

    private func fetchBooks(query: String, field: BookSearchField) async throws -> [Book] {
        async let olTask = searchOpenLibrary(query: query, field: field)
        async let gbTask = searchGoogleBooks(query: query, field: field)

        let (olBooks, gbBooks) = await (
            (try? olTask) ?? [],
            (try? gbTask) ?? []
        )

        var seen = Set<String>()
        var merged: [Book] = []

        for book in olBooks {
            let key = "\(book.title.lowercased())|\(book.author.lowercased())"
            if seen.insert(key).inserted { merged.append(book) }
        }

        for book in gbBooks {
            let key = "\(book.title.lowercased())|\(book.author.lowercased())"
            if seen.insert(key).inserted { merged.append(book) }
        }

        let queryNormalized = normalize(query)
        let queryWords = queryNormalized.split(separator: " ").map(String.init)

        merged.sort {
            let lScore = relevanceScore(book: $0, query: queryNormalized, words: queryWords, field: field)
            let rScore = relevanceScore(book: $1, query: queryNormalized, words: queryWords, field: field)
            if lScore != rScore { return lScore < rScore }
            return $0.title < $1.title
        }

        return merged.filter { book in
            // ISBN queries are already exact matches at the API level
            guard field != .isbn else { return true }

            let titleWords = normalize(book.title).components(separatedBy: .whitespacesAndNewlines)
            let authorWords = normalize(book.author).components(separatedBy: .whitespacesAndNewlines)

            let significantWords = queryWords.filter { $0.count > 2 }

            // For author searches only require the surname to match
            let wordsToMatch = field == .author
                ? Array(significantWords.suffix(1))
                : significantWords

            guard !wordsToMatch.isEmpty else { return true }

            // Allow one non-matching word on longer queries to tolerate typos/extra words
            let requiredMatches = wordsToMatch.count <= 2 ? wordsToMatch.count : wordsToMatch.count - 1

            let titleMatches = wordsToMatch.filter { qWord in
                titleWords.contains(where: { $0.hasPrefix(qWord) || $0.contains(qWord) })
            }.count
            let authorMatches = wordsToMatch.filter { qWord in
                authorWords.contains(where: { $0.hasPrefix(qWord) || $0.contains(qWord) })
            }.count

            return titleMatches >= requiredMatches || authorMatches >= requiredMatches
        }
    }

    /// Case- and diacritic-insensitive, punctuation-stripped comparison key.
    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: .punctuationCharacters)
            .joined()
    }

    private func relevanceScore(book: Book, query: String, words: [String], field: BookSearchField) -> Int {
        let target = field == .author
            ? normalize(book.author)
            : normalize(book.title)

        if target == query { return 0 }
        if target.hasPrefix(query) { return 1 }
        if target.contains(query) { return 2 }
        if words.allSatisfy({ target.contains($0) }) { return 3 }
        return 4
    }

    // MARK: - Open Library (primary)

    private func searchOpenLibrary(query: String, field: BookSearchField) async throws -> [Book] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let param: String
        switch field {
        case .author: param = "author"
        case .title:  param = "title"
        case .isbn:   param = "isbn"
        }
        let urlString = "https://openlibrary.org/search.json?\(param)=\(encoded)&fields=key,title,author_name,isbn,cover_i,edition_count&limit=30"

        guard let url = URL(string: urlString) else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw AppError("Open Library search failed (\(http.statusCode))")
        }

        let decoded = try JSONDecoder().decode(OLSearchResponse.self, from: data)

        var seen = Set<String>()
        return decoded.docs.compactMap { doc in
            guard let title = doc.title,
                  !title.trimmingCharacters(in: .whitespaces).isEmpty
            else { return nil }

            let author = doc.authorName?.first ?? "Unknown Author"

            let dedupKey = "\(title.lowercased())|\(author.lowercased())"
            guard seen.insert(dedupKey).inserted else { return nil }

            let coverURL: String? = doc.coverId.map {
                "https://covers.openlibrary.org/b/id/\($0)-M.jpg"
            }

            let isbn = doc.isbn?.first
            let olKey = doc.key?.replacingOccurrences(of: "/works/", with: "") ?? UUID().uuidString

            return Book(
                id: UUID(),
                googleBooksId: "OL_\(olKey)",
                title: title,
                author: author,
                coverURL: coverURL,
                isbn: isbn,
                createdAt: .now
            )
        }
    }

    // MARK: - Google Books (modern/recent titles)
 
    private func searchGoogleBooks(query: String, field: BookSearchField) async throws -> [Book] {
        let normalized = query
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let fieldPrefix: String
        switch field {
        case .author: fieldPrefix = "inauthor"
        case .title:  fieldPrefix = "intitle"
        case .isbn:   fieldPrefix = "isbn"
        }

        // Wrap multi-word queries in quotes so "J K Rowling" isn't split into separate terms
        let fieldQuery: String
        if normalized.contains(" ") {
            guard let quotedEncoded = "\"\(normalized)\""
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            else { return [] }
            fieldQuery = "\(fieldPrefix):\(quotedEncoded)"
        } else {
            fieldQuery = "\(fieldPrefix):\(encoded)"
        }

        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(fieldQuery)&maxResults=20&printType=books&orderBy=relevance&key=\(Config.googleBooksKey)"

        guard let url = URL(string: urlString) else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            throw AppError("Google Books API error \(http.statusCode): \(body)")
        }

        let decoded = try JSONDecoder().decode(GBResponse.self, from: data)

        let junkWords = [
            "coloring", "colouring", "journal", "notebook",
            "planner", "agenda", "summary", "workbook",
            "baby sitter", "log book", "puzzle", "activity book",
            "study guide", "cliff notes"
        ]

        var seen = Set<String>()
        return decoded.items?.compactMap { item in
            guard let info = item.volumeInfo,
                  let title = info.title,
                  let authors = info.authors, !authors.isEmpty
            else { return nil }

            let titleLower = title.lowercased()
            if junkWords.contains(where: { titleLower.contains($0) }) { return nil }

            let key = "\(titleLower)|\(authors[0].lowercased())"
            guard seen.insert(key).inserted else { return nil }

            // Only use Google's own thumbnail — don't build fake Open Library ISBN URLs
            let isbn = info.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
                ?? info.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier

            let coverURL: String?
            if let thumb = info.imageLinks?.thumbnail {
                coverURL = thumb
                    .replacingOccurrences(of: "http://", with: "https://")
                    + "&fife=w200"
            } else {
                coverURL = nil
            }

            return Book(
                id: UUID(),
                googleBooksId: item.id,
                title: title,
                author: authors[0],
                coverURL: coverURL,
                isbn: isbn,
                createdAt: .now
            )
        } ?? []
    }
    
}

// MARK: - Open Library types

private struct OLSearchResponse: Decodable {
    let docs: [OLDoc]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        docs = (try? container.decode([OLDoc].self, forKey: .docs)) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case docs
    }
}

private struct OLDoc: Decodable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let isbn: [String]?
    let coverId: Int?
    let editionCount: Int?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName   = "author_name"
        case isbn
        case coverId      = "cover_i"
        case editionCount = "edition_count"
    }
}

// MARK: - Google Books types

private struct GBResponse: Decodable {
    let items: [GBItem]?
}

private struct GBItem: Decodable {
    let id: String
    let volumeInfo: GBVolumeInfo?

    struct GBVolumeInfo: Decodable {
        let title: String?
        let authors: [String]?
        let imageLinks: GBImageLinks?
        let industryIdentifiers: [GBIdentifier]?

        struct GBImageLinks: Decodable {
            let thumbnail: String?
        }

        struct GBIdentifier: Decodable {
            let type: String
            let identifier: String
        }
    }
}
