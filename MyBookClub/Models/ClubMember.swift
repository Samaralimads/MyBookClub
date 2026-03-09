//
//  ClubMember.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct ClubMember: Codable, Identifiable {
    var id: String { "\(clubId)-\(userId)" }
    let clubId: UUID
    let userId: UUID
    var role: MemberRole
    var status: MemberStatus
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case clubId   = "club_id"
        case userId   = "user_id"
        case role
        case status
        case joinedAt = "joined_at"
    }
}

enum MemberRole: String, Codable {
    case member    = "member"
    case organiser = "organiser"
}

enum MemberStatus: String, Codable {
    case active  = "active"
    case pending = "pending"
}
