//
//  Meeting.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct Meeting: Codable, Identifiable, Hashable {
    let id: UUID
    let clubId: UUID
    var title: String
    var scheduledAt: Date
    var chaptersDue: Int?
    var notes: String?
    var meetingURL: String?
    var notifSent24h: Bool
    var notifSent1h: Bool
    let createdAt: Date

    // Joined
    var clubName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId       = "club_id"
        case title
        case scheduledAt  = "scheduled_at"
        case chaptersDue  = "chapters_due"
        case notes
        case meetingURL   = "meeting_url"
        case notifSent24h = "notif_sent_24h"
        case notifSent1h  = "notif_sent_1h"
        case createdAt    = "created_at"
        case clubName     = "club_name"
    }
}
