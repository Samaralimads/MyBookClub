//
//  Book.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct Book: Codable, Identifiable, Hashable {
    let id: UUID
    let googleBooksId: String
    let title: String
    let author: String
    var coverURL: String?
    var isbn: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case googleBooksId = "google_books_id"
        case title
        case author
        case coverURL      = "cover_url"
        case isbn
        case createdAt     = "created_at"
    }

    /// Returns the best available cover URL, falling back to Open Library
    var displayCoverURL: URL? {
        if let urlString = coverURL, let url = URL(string: urlString) {
            return url
        }
        if let isbn = isbn {
            return URL(string: "https://covers.openlibrary.org/b/isbn/\(isbn)-M.jpg")
        }
        return nil
    }
}
