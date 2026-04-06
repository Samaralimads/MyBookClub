//
//  ClubHistoryViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 18/03/2026.
//

import Foundation

@Observable
final class ClubHistoryViewModel {

    // MARK: - State

    private(set) var entries: [ClubBookHistory] = []
    private(set) var ratings: [UUID: BookRating] = [:]
    private(set) var isLoading = false
    var error: AppError?

    // MARK: - Load

    func load(club: Club) async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await SupabaseService.shared.fetchBookHistory(clubId: club.id)
            await withTaskGroup(of: Void.self) { group in
                for entry in entries {
                    group.addTask { await self.loadRating(clubId: club.id, bookId: entry.book.id) }
                }
            }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Rating

    func loadRating(clubId: UUID, bookId: UUID) async {
        do {
            let rating = try await SupabaseService.shared.fetchBookRating(
                clubId: clubId,
                bookId: bookId
            )
            ratings[bookId] = rating
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func submitRating(clubId: UUID, bookId: UUID, stars: Double) async {
        // Optimistic update
        let current = ratings[bookId]
        ratings[bookId] = BookRating(
            myRating: stars,
            avgRating: current?.avgRating,
            ratingCount: current?.ratingCount ?? 0
        )
        do {
            try await SupabaseService.shared.upsertBookRating(
                clubId: clubId,
                bookId: bookId,
                rating: stars
            )
            // Reload to get updated group average
            let updated = try await SupabaseService.shared.fetchBookRating(
                clubId: clubId,
                bookId: bookId
            )
            ratings[bookId] = updated
        } catch {
            // Revert optimistic update on failure
            ratings[bookId] = current
            self.error = AppError(underlying: error)
        }
    }
}
