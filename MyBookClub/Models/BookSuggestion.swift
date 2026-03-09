//
//  BookSuggestion.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct BookSuggestion: Codable, Identifiable {
    let id: UUID          // vote_session_id + book_id composite used as id
    let book: Book
    var voteCount: Int
    var hasVoted: Bool    // whether the current user has voted for this

    enum CodingKeys: String, CodingKey {
        case id
        case book      = "books"
        case voteCount = "vote_count"
        case hasVoted  = "has_voted"
    }
}
