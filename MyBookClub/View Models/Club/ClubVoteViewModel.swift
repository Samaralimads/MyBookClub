//
//  ClubVoteViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 20/03/2026.
//

import Foundation

@Observable
final class ClubVoteViewModel {

    private(set) var activeSession: VoteSession?
    private(set) var isLoading = false
    var isVoting = false
    var error: AppError?

    // Confirmation dialog state
    var pendingWinnerSuggestion: BookSuggestion?

    // MARK: - Load

    func load(clubId: UUID, hasCurrentBook: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard !hasCurrentBook else {
                activeSession = nil
                return
            }
            if var session = try await SupabaseService.shared.fetchActiveVoteSession(clubId: clubId) {
                session.suggestions = try await SupabaseService.shared.fetchSuggestions(sessionId: session.id)
                activeSession = session
            } else {
                var session = try await SupabaseService.shared.openVoteSession(clubId: clubId, deadline: nil)
                session.suggestions = []
                activeSession = session
            }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Open session (organiser)

    func openSession(clubId: UUID) async {
        isVoting = true
        defer { isVoting = false }
        do {
            let deadline = Calendar.current.date(byAdding: .day, value: 7, to: .now)
            var session = try await SupabaseService.shared.openVoteSession(clubId: clubId, deadline: deadline)
            session.suggestions = []
            activeSession = session
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Suggest a book

    func suggestBook(_ book: Book, clubId: UUID) async {
        guard let session = activeSession else { return }
        do {
            let saved = try await SupabaseService.shared.cacheBook(book)
            try await SupabaseService.shared.suggestBook(
                voteSessionId: session.id,
                bookId: saved.id,
                clubId: clubId
            )
            var updated = session
            updated.suggestions = try await SupabaseService.shared.fetchSuggestions(sessionId: session.id)
            activeSession = updated
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Cast vote

    func castVote(suggestion: BookSuggestion, sessionId: UUID, clubId: UUID) async {
        isVoting = true
        defer { isVoting = false }
        do {
            if suggestion.hasVoted {
                try await SupabaseService.shared.removeVote(
                    voteSessionId: sessionId,
                    bookId: suggestion.book.id
                )
            } else {
                try await SupabaseService.shared.castVote(
                    voteSessionId: sessionId,
                    bookId: suggestion.book.id,
                    clubId: clubId
                )
            }
            if var session = activeSession {
                session.suggestions = try await SupabaseService.shared.fetchSuggestions(sessionId: sessionId)
                activeSession = session
            }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Close session (organiser)

    func closeSession(session: VoteSession, winnerBookId: UUID, clubId: UUID) async -> Book? {
        isVoting = true
        defer { isVoting = false }
        do {
            try await SupabaseService.shared.closeVoteSession(
                voteSessionId: session.id,
                winnerBookId: winnerBookId,
                clubId: clubId
            )
            let winningBook = session.suggestions?.first { $0.book.id == winnerBookId }?.book
            activeSession = nil
            pendingWinnerSuggestion = nil
            return winningBook
        } catch {
            self.error = AppError(underlying: error)
            return nil
        }
    }
}
