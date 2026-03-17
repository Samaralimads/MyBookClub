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
    var fromChapter: Int?
    var toChapter: Int?
    var chapterTitles: [String]?
    var notes: String?
    var address: String?
    var notifSent24h: Bool
    var notifSent1h: Bool
    let createdAt: Date

    // Joined
    var clubName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId        = "club_id"
        case title
        case scheduledAt   = "scheduled_at"
        case fromChapter   = "from_chapter"
        case toChapter     = "to_chapter"
        case chapterTitles = "chapter_titles"
        case notes
        case address
        case notifSent24h  = "notif_sent_24h"
        case notifSent1h   = "notif_sent_1h"
        case createdAt     = "created_at"
        case clubName      = "club_name"
    }

    // The assigned chapter range for this meeting, if both bounds are set.
    var chapterRange: ClosedRange<Int>? {
        guard let from = fromChapter, let to = toChapter, from <= to else { return nil }
        return from...to
    }

    // Title for a specific chapter number, if chapter titles were provided.
    func title(for chapter: Int) -> String? {
        guard let from = fromChapter, let titles = chapterTitles else { return nil }
        let index = chapter - from
        guard titles.indices.contains(index) else { return nil }
        let t = titles[index]
        return t.isEmpty ? nil : t
    }
}
