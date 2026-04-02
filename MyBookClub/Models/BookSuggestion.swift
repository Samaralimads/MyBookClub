//
//  BookSuggestion.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct BookSuggestion: Codable, Identifiable {
    let id: UUID
    let book: Book
    var voteCount: Int
    var hasVoted: Bool
    var suggestedByName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case book            = "books"
        case voteCount       = "vote_count"
        case hasVoted        = "has_voted"
        case suggestedByName = "suggested_by_name"
    }
}
