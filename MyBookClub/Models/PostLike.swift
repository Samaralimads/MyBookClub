//
//  PostLike.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 07/04/2026.
//

import Foundation

struct PostLike: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postId    = "post_id"
        case userId    = "user_id"
        case createdAt = "created_at"
    }
}
