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

    // Joined fields (populated by joins / RPC)
    var currentBook: Book?
    var memberCount: Int?

    // Returned by nearby_clubs RPC — distance in metres from user's location.
    // nil when fetched directly (e.g. fetchClub by ID).
    var distanceMeters: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case organiserId    = "organiser_id"
        case name
        case description
        case coverImageURL  = "cover_image_url"
        case genreTags      = "genre_tags"
        case cityLabel      = "city_label"
        case isPublic       = "is_public"
        case memberCap      = "member_cap"
        case recurringDay   = "recurring_day"
        case recurringTime  = "recurring_time"
        case currentBookId  = "current_book_id"
        case createdAt      = "created_at"
        case currentBook    = "books"
        case memberCount    = "member_count"
        case distanceMeters = "distance_meters"
    }
}

extension Club {

    // MARK: - Discover Mock Data (list + map)

    static let mockDiscover: [Club] = [
        Club(
            id: UUID(),
            organiserId: nil,
            name: "The Page Turners",
            description: "A cosy group of literary fiction lovers who meet weekly over coffee in the Marais.",
            coverImageURL: nil,
            genreTags: ["literary-fiction"],
            cityLabel: "Le Marais, Paris",
            isPublic: true,
            memberCap: 15,
            recurringDay: "Tuesday",
            recurringTime: "19:00",
            currentBookId: nil,
            createdAt: .now,
            memberCount: 12,
            distanceMeters: 800
        ),
        Club(
            id: UUID(),
            organiserId: nil,
            name: "Sci-Fi Saturdays",
            description: "We explore the galaxy one book at a time. From Asimov to Liu Cixin — all welcome.",
            coverImageURL: nil,
            genreTags: ["sci-fi"],
            cityLabel: "Saint-Germain, Paris",
            isPublic: true,
            memberCap: 20,
            recurringDay: "Saturday",
            recurringTime: "15:00",
            currentBookId: nil,
            createdAt: .now,
            memberCount: 8,
            distanceMeters: 1_900
        ),
        Club(
            id: UUID(),
            organiserId: nil,
            name: "Nonfiction Navigators",
            description: "Real stories only. History, memoir, science — we dive deep into truth every month.",
            coverImageURL: nil,
            genreTags: ["non-fiction"],
            cityLabel: "Montmartre, Paris",
            isPublic: false,
            memberCap: 25,
            recurringDay: "Friday",
            recurringTime: "19:00",
            currentBookId: nil,
            createdAt: .now,
            memberCount: 22,
            distanceMeters: 4_000
        ),
        Club(
            id: UUID(),
            organiserId: nil,
            name: "Mystery & Merlot",
            description: "Thrillers, whodunits and wine. We vote on the book, bring your own glass.",
            coverImageURL: nil,
            genreTags: ["mystery"],
            cityLabel: "Bastille, Paris",
            isPublic: true,
            memberCap: 12,
            recurringDay: "Wednesday",
            recurringTime: "20:00",
            currentBookId: nil,
            createdAt: .now,
            memberCount: 10,
            distanceMeters: 2_600
        ),
        Club(
            id: UUID(),
            organiserId: nil,
            name: "Graphic Novel Gazette",
            description: "Manga, bandes dessinées, superhero arcs — we read everything with pictures.",
            coverImageURL: nil,
            genreTags: ["graphic-novel"],
            cityLabel: "Oberkampf, Paris",
            isPublic: true,
            memberCap: 18,
            recurringDay: "Sunday",
            recurringTime: "14:00",
            currentBookId: nil,
            createdAt: .now,
            memberCount: 15,
            distanceMeters: 3_100
        ),
    ]

    // MARK: - Map Pin Coordinates (Paris area, aligned with mockDiscover order)

    /// Lat/lng pairs corresponding to each club in `mockDiscover`.
    static let mockPinCoordinates: [(Double, Double)] = [
        (48.860, 2.347),  // The Page Turners — Le Marais
        (48.855, 2.332),  // Sci-Fi Saturdays — Saint-Germain
        (48.884, 2.340),  // Nonfiction Navigators — Montmartre
        (48.852, 2.370),  // Mystery & Merlot — Bastille
        (48.865, 2.378),  // Graphic Novel Gazette — Oberkampf
    ]
}





