//
//  MeetingsViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

@Observable
final class MeetingsViewModel {

    // MARK: - State

    private(set) var meetings: [Meeting] = []
    private(set) var isLoading = false
    var error: AppError?

    // MARK: - Derived

    var upcomingMeetings: [Meeting] {
        meetings
            .filter { $0.scheduledAt >= .now }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var pastMeetings: [Meeting] {
        meetings
            .filter { $0.scheduledAt < .now }
            .sorted { $0.scheduledAt > $1.scheduledAt }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            meetings = try await SupabaseService.shared.fetchUpcomingMeetingsForUser()
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
