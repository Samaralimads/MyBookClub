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
    var error: AppError?

    // MARK: - Load

    func load(club: Club, isMember: Bool) async {
        guard let book = club.currentBook else { return }
        guard isMember else { return }
        do {
            readingProgress = try await SupabaseService.shared.fetchReadingProgress(
                clubId: club.id,
                bookId: book.id
            )
        } catch {
            self.error = AppError(underlying: error)
        }
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

    // MARK: - Archive (organiser only, explicit action)

    func archiveCurrentBook(club: Club) async -> Bool {
        guard let bookId = club.currentBookId else { return false }
        do {
            try await SupabaseService.shared.archiveBook(clubId: club.id, bookId: bookId)
            return true
        } catch {
            self.error = AppError(underlying: error)
            return false
        }
    }
}
