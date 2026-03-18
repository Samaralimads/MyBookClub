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

    private(set) var readingProgress: ReadingProgress?
    var isSettingBook = false
    var error: AppError?

    // MARK: - Load

    func load(club: Club, isMember: Bool) async -> Bool {
        let archived = await checkAndArchiveIfNeeded(club: club)
        if archived { return true }
        guard let book = club.currentBook else { return false }
        guard isMember else { return false }
        do {
            readingProgress = try await SupabaseService.shared.fetchReadingProgress(
                clubId: club.id,
                bookId: book.id
            )
        } catch {
            self.error = AppError(underlying: error)
        }
        return false
    }

    // MARK: - Toggle chapter completion

    func toggleChapter(clubId: UUID, bookId: UUID, chapter: Int) async {
        var completed = Set(readingProgress?.completedChapters ?? [])
        if completed.contains(chapter) {
            completed.remove(chapter)
        } else {
            completed.insert(chapter)
        }
        let sorted = completed.sorted()

        // Optimistic update — only works if readingProgress already exists
        readingProgress?.completedChapters = sorted

        do {
            try await SupabaseService.shared.upsertReadingProgress(
                clubId: clubId,
                bookId: bookId,
                completedChapters: sorted
            )

            if readingProgress == nil {
                readingProgress = try await SupabaseService.shared.fetchReadingProgress(
                    clubId: clubId,
                    bookId: bookId
                )
            }
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

    // MARK: - Auto-archive check

    func checkAndArchiveIfNeeded(club: Club) async -> Bool {
        guard let bookId = club.currentBookId else { return false }
        do {
            guard let finalMeeting = try await SupabaseService.shared.fetchFinalMeeting(clubId: club.id)
            else { return false }
            guard finalMeeting.scheduledAt < Date.now else { return false }
            try await SupabaseService.shared.archiveBook(clubId: club.id, bookId: bookId)
            return true
        } catch {
            self.error = AppError(underlying: error)
            return false
        }
    }
}
