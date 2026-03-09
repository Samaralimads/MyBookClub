//
//  VoteSession.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct VoteSession: Codable, Identifiable {
    let id: UUID
    let clubId: UUID
    var status: VoteStatus
    var deadline: Date?
    var winnerBookId: UUID?
    let createdAt: Date

    // Joined
    var suggestions: [BookSuggestion]?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId       = "club_id"
        case status
        case deadline
        case winnerBookId = "winner_book_id"
        case createdAt    = "created_at"
        case suggestions
    }
}

enum VoteStatus: String, Codable {
    case open   = "open"
    case closed = "closed"
}
