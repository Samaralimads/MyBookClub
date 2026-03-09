//
//  Club.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct Club: Codable, Identifiable, Hashable {
    let id: UUID
    var organiserId: UUID?
    var name: String
    var description: String?
    var coverImageURL: String?
    var genreTags: [String]
    // location stored as PostGIS — we receive lat/lng separately in queries
    var cityLabel: String
    var isPublic: Bool
    var memberCap: Int
    var recurringDay: String?
    var recurringTime: String?   // "HH:mm:ss" from PostgreSQL time
    var currentBookId: UUID?
    let createdAt: Date

    // Joined fields (not in DB column, populated by joins)
    var currentBook: Book?
    var memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case organiserId     = "organiser_id"
        case name
        case description
        case coverImageURL   = "cover_image_url"
        case genreTags       = "genre_tags"
        case cityLabel       = "city_label"
        case isPublic        = "is_public"
        case memberCap       = "member_cap"
        case recurringDay    = "recurring_day"
        case recurringTime   = "recurring_time"
        case currentBookId   = "current_book_id"
        case createdAt       = "created_at"
        case currentBook     = "books"
        case memberCount     = "member_count"
    }
}
