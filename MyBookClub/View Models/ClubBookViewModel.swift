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

        // Optimistic update
        readingProgress?.completedChapters = sorted

        do {
            try await SupabaseService.shared.upsertReadingProgress(
                clubId: clubId,
                bookId: bookId,
                completedChapters: sorted
            )
        } catch {
            // Roll back on failure
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
}
