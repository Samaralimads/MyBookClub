//
//  BookSearchService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

@Observable
final class BookSearchService {

    var results: [Book] = []
    var isLoading = false
    var error: AppError?

    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }

        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            let books = try await fetchBooks(query: query)
            results = books
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Search logic

    private func fetchBooks(query: String) async throws -> [Book] {
        // 1. Try Google Books
        if let books = try? await searchGoogleBooks(query: query), !books.isEmpty {
            return books
        }
        // 2. Fallback to Open Library
        return (try? await searchOpenLibrary(query: query)) ?? []
    }

    // MARK: - Google Books

    private func searchGoogleBooks(query: String) async throws -> [Book] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&maxResults=10&key=\(Config.googleBooksKey)"
        guard let url = URL(string: urlString) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return response.items?.compactMap { item in
            guard let volumeInfo = item.volumeInfo,
                  let title = volumeInfo.title
            else { return nil }

            let coverURL = volumeInfo.imageLinks?.thumbnail?
                .replacingOccurrences(of: "http://", with: "https://")  // force HTTPS

            return Book(
                id: UUID(),
                googleBooksId: item.id,
                title: title,
                author: volumeInfo.authors?.first ?? "Unknown Author",
                coverURL: coverURL,
                isbn: volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier,
                createdAt: Date()
            )
        } ?? []
    }

    // MARK: - Open Library fallback

    private func searchOpenLibrary(query: String) async throws -> [Book] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        let urlString = "https://openlibrary.org/search.json?q=\(encodedQuery)&limit=10"
        guard let url = URL(string: urlString) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)

        return response.docs?.prefix(10).compactMap { doc in
            guard let title = doc.title, let key = doc.key else { return nil }

            let isbn = doc.isbn?.first
            let coverURL: String? = isbn.map {
                "https://covers.openlibrary.org/b/isbn/\($0)-M.jpg"
            }

            // Use a stable ID derived from the Open Library key
            return Book(
                id: UUID(),
                googleBooksId: "OL_\(key.replacingOccurrences(of: "/works/", with: ""))",
                title: title,
                author: doc.authorName?.first ?? "Unknown Author",
                coverURL: coverURL,
                isbn: isbn,
                createdAt: Date()
            )
        } ?? []
    }
}

// MARK: - Google Books API types

private struct GoogleBooksResponse: Decodable {
    let items: [GoogleBooksItem]?
}

private struct GoogleBooksItem: Decodable {
    let id: String
    let volumeInfo: VolumeInfo?

    struct VolumeInfo: Decodable {
        let title: String?
        let authors: [String]?
        let imageLinks: ImageLinks?
        let industryIdentifiers: [IndustryIdentifier]?

        struct ImageLinks: Decodable {
            let thumbnail: String?
        }
        struct IndustryIdentifier: Decodable {
            let type: String
            let identifier: String
        }
    }
}

// MARK: - Open Library API types

private struct OpenLibraryResponse: Decodable {
    let docs: [OpenLibraryDoc]?
}

private struct OpenLibraryDoc: Decodable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let isbn: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title
        case authorName = "author_name"
        case isbn
    }
}
