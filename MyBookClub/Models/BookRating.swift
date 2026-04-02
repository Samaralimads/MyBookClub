//
//  BookRating.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import Foundation

struct BookRating: Decodable {
    let myRating: Int?
    let avgRating: Double?
    let ratingCount: Int

    enum CodingKeys: String, CodingKey {
        case myRating    = "my_rating"
        case avgRating   = "avg_rating"
        case ratingCount = "rating_count"
    }
}
