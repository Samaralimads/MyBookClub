//
//  Genre.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

enum Genre: String, CaseIterable, Codable {
    case literaryFiction  = "literary-fiction"
    case mystery          = "mystery"
    case thriller         = "thriller"
    case sciFi            = "sci-fi"
    case fantasy          = "fantasy"
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
        case .mystery:           return "Mystery"
        case .thriller:          return "Thriller"
        case .sciFi:             return "Sci-Fi"
        case .fantasy:           return "Fantasy"
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
