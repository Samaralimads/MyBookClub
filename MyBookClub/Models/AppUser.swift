//
//  AppUser.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct AppUser: Codable, Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var bio: String?
    var avatarURL: String?
    var genrePrefs: [String]?
    var currentlyReadingBookId: UUID?
    var city: String?
    var readingFreq: ReadingFrequency?
    var apnsToken: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName            = "display_name"
        case bio
        case avatarURL              = "avatar_url"
        case genrePrefs             = "genre_prefs"
        case currentlyReadingBookId = "currently_reading_book_id"
        case city
        case readingFreq            = "reading_freq"
        case apnsToken              = "apns_token"
        case createdAt              = "created_at"
    }
}

enum ReadingFrequency: String, Codable, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"

    var label: String {
        switch self {
        case .daily:   return "Daily"
        case .weekly:  return "A few times a week"
        case .monthly: return "A few times a month"
        }
    }
}
