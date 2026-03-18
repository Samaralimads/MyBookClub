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
    private(set) var isLoading = false
    var error: AppError?

    // MARK: - Load

    func load(club: Club) async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await SupabaseService.shared.fetchBookHistory(clubId: club.id)
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
