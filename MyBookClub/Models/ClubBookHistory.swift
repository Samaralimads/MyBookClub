//
//  ClubBookHistory.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 18/03/2026.
//

import Foundation

struct ClubBookHistory: Identifiable, Decodable {
    let id: UUID
    let clubId: UUID
    let bookId: UUID
    let addedAt: Date
    let finishedAt: Date
    let book: Book

    enum CodingKeys: String, CodingKey {
        case id
        case clubId     = "club_id"
        case bookId     = "book_id"
        case addedAt    = "added_at"
        case finishedAt = "finished_at"
        case book       = "books"
    }
}
