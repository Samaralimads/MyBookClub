//
//  MeetingRSVP.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 30/03/2026.
//

import Foundation

// MARK: - RSVP status

enum RSVPStatus: String, Codable, Hashable {
    case going    = "going"
    case notGoing = "not_going"
}

// MARK: - The user's own persisted RSVP row

struct MeetingRSVP: Codable, Identifiable {
    let id: UUID
    let meetingId: UUID
    let status: RSVPStatus
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case meetingId = "meeting_id"
        case status
        case updatedAt = "updated_at"
    }
}

// MARK: - One row returned by get_meeting_rsvps()

struct RSVPMember: Codable, Identifiable {
    let userId: UUID
    let displayName: String
    let avatarURL: String?
    let status: RSVPStatus

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId      = "user_id"
        case displayName = "display_name"
        case avatarURL   = "avatar_url"
        case status
    }
}

// MARK: - Aggregate counts (decoded from meeting_rsvp_counts view)

struct RSVPCounts: Codable {
    let goingCount: Int
    let notGoingCount: Int

    enum CodingKeys: String, CodingKey {
        case goingCount    = "going_count"
        case notGoingCount = "not_going_count"
    }
}
