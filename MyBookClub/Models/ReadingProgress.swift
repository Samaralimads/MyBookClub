//
//  ReadingProgress.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct ReadingProgress: Codable, Identifiable, Equatable {
    let id: UUID
    let clubId: UUID
    let userId: UUID
    let bookId: UUID
    //Chapter numbers the member has checked off for the current meeting assignment.
    var completedChapters: [Int]
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clubId             = "club_id"
        case userId             = "user_id"
        case bookId             = "book_id"
        case completedChapters  = "completed_chapters"
        case updatedAt          = "updated_at"
    }

    func isCompleted(_ chapter: Int) -> Bool {
        completedChapters.contains(chapter)
    }
}
