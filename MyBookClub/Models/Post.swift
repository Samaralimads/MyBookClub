//
//  Post.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct Post: Codable, Identifiable {
    let id: UUID
    let clubId: UUID
    var userId: UUID?
    var postType: PostType
    var parentPostId: UUID?
    var content: String
    var isSpoiler: Bool
    var isPinned: Bool?
    let createdAt: Date

    // Joined
    var author: AppUser?
    var comments: [Post]?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId       = "club_id"
        case userId       = "user_id"
        case postType     = "post_type"
        case parentPostId = "parent_post_id"
        case content
        case isSpoiler    = "is_spoiler"
        case isPinned     = "is_pinned"
        case createdAt    = "created_at"
        case author       = "users"
        case comments
    }
}

enum PostType: String, Codable {
    case announcement = "announcement"
    case comment      = "comment"
}
