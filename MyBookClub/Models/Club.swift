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
    var cityLabel: String
    var lat: Double?
    var lng: Double?
    var isPublic: Bool
    var memberCap: Int
    var currentBookId: UUID?
    let createdAt: Date

    var currentBook: Book?
    var memberCount: Int?
    var distanceMeters: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case organiserId    = "organiser_id"
        case name
        case description
        case coverImageURL  = "cover_image_url"
        case genreTags      = "genre_tags"
        case cityLabel      = "city_label"
        case lat
        case lng
        case isPublic       = "is_public"
        case memberCap      = "member_cap"
        case currentBookId  = "current_book_id"
        case createdAt      = "created_at"
        case currentBook    = "books"
        case memberCount    = "member_count"
        case distanceMeters = "distance_meters"
    }
}
