//
//  ClubBookViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 13/03/2026.
//

import Foundation

@Observable
final class ClubBookViewModel {

    // MARK: - State

    private(set) var nextMeeting: Meeting?
    private(set) var readingProgress: ReadingProgress?
    var isSettingBook = false
    var error: AppError?

    // MARK: - Load

    func load(club: Club, isMember: Bool) async {
        guard let book = club.currentBook else { return }
        async let meetingResult = fetchNextMeeting(clubId: club.id)
        async let progressResult = isMember ? fetchProgress(clubId: club.id, bookId: book.id) : nil

        do {
            nextMeeting = try await meetingResult
            readingProgress = try await progressResult
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Reading progress

    func updateProgress(clubId: UUID, bookId: UUID, chapter: Int) async {
        do {
            try await SupabaseService.shared.upsertReadingProgress(
                clubId: clubId,
                bookId: bookId,
                currentChapter: chapter
            )
            readingProgress?.currentChapter = chapter
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Set current book (organiser only)

    func setCurrentBook(club: Club, book: Book) async {
        isSettingBook = true
        defer { isSettingBook = false }
        do {
            try await SupabaseService.shared.setCurrentBook(clubId: club.id, book: book)
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Private helpers

    private func fetchNextMeeting(clubId: UUID) async throws -> Meeting? {
        let meetings = try await SupabaseService.shared.fetchMeetings(clubId: clubId)
        return meetings.first { $0.scheduledAt > .now }
    }

    private func fetchProgress(clubId: UUID, bookId: UUID) async throws -> ReadingProgress? {
        try await SupabaseService.shared.fetchReadingProgress(clubId: clubId, bookId: bookId)
    }
}
