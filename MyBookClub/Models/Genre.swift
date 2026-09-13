//
//  Genre.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

enum Genre: String, CaseIterable, Codable {
    case literaryFiction  = "literary-fiction"
    case mysteryThriller  = "mystery-thriller"
    case sciFiFantasy     = "sci-fi-fantasy"
    case romance          = "romance"
    case historicalFiction = "historical-fiction"
    case nonFiction       = "non-fiction"
    case biography        = "biography"
    case horror           = "horror"
    case graphicNovel     = "graphic-novel"
    case poetry           = "poetry"

    var label: String {
        switch self {
        case .literaryFiction:   return "Literary Fiction"
        case .mysteryThriller:   return "Mystery & Thriller"
        case .sciFiFantasy:      return "Sci-Fi & Fantasy"
        case .romance:           return "Romance"
        case .historicalFiction: return "Historical Fiction"
        case .nonFiction:        return "Non-Fiction"
        case .biography:         return "Biography"
        case .horror:            return "Horror"
        case .graphicNovel:      return "Graphic Novel"
        case .poetry:            return "Poetry"
        }
    }

}

extension Genre {
    // Raw values retired when mystery/thriller and sci-fi/fantasy were merged.
    // Clubs/profiles saved before that change still carry these strings.
    private static let legacyRawValues: [String: Genre] = [
        "mystery":  .mysteryThriller,
        "thriller": .mysteryThriller,
        "sci-fi":   .sciFiFantasy,
        "fantasy":  .sciFiFantasy,
    ]

    init?(legacyRawValue raw: String) {
        if let match = Genre(rawValue: raw) {
            self = match
        } else if let legacy = Genre.legacyRawValues[raw] {
            self = legacy
        } else {
            return nil
        }
    }
}
