//
//  ProfileViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - State

    var user: AppUser?
    var clubCount: Int = 0
    var booksRead: Int = 0
    var currentlyReadingBooks: [(book: Book, clubName: String)] = []
    var isLoading = false
    var error: AppError?

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            async let fetchedUser    = SupabaseService.shared.fetchCurrentUser()
            async let fetchedClubs   = SupabaseService.shared.fetchMyClubs()
            async let fetchedHistory = SupabaseService.shared.fetchBooksReadCount()

            let (resolvedUser, resolvedClubs, resolvedHistory) = try await (fetchedUser, fetchedClubs, fetchedHistory)

            user      = resolvedUser
            clubCount = resolvedClubs.count
            booksRead = resolvedHistory
            currentlyReadingBooks = resolvedClubs.compactMap { club in
                guard let book = club.currentBook else { return nil }
                return (book: book, clubName: club.name)
            }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Derived

    /// Derives up to two initials from the user's display name.
    var avatarInitials: String {
        guard let name = user?.displayName, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2 {
            return (parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}
