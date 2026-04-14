//
//  SettingsViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {

    var isExporting = false
    var isDeleting  = false
    var exportedURL: URL?
    var error: AppError?

    // Confirmation dialogs
    var showDeleteConfirm = false

    private let iso8601 = ISO8601DateFormatter()

    // MARK: - Export My Data (GDPR)

    func exportData() async {
        isExporting = true
        defer { isExporting = false }
        error = nil

        do {
            let user    = try await SupabaseService.shared.fetchCurrentUser()
            let clubs   = try await SupabaseService.shared.fetchMyClubs()

            // Build a simple JSON payload
            struct ExportPayload: Encodable {
                let profile: AppUser
                let clubs: [Club]
                let exportedAt: String
            }

            let payload = ExportPayload(
                profile: user,
                clubs: clubs,
                exportedAt: iso8601.string(from: .now)
            )

            let data = try JSONEncoder().encode(payload)
            let url  = FileManager.default.temporaryDirectory
                .appending(path: "mybookclub_export.json")
            try data.write(to: url)
            exportedURL = url
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Delete Account (GDPR)

    func deleteAccount(authViewModel: AuthViewModel) async {
        isDeleting = true
        defer { isDeleting = false }
        error = nil

        do {
            try await SupabaseService.shared.deleteCurrentUser()
            await authViewModel.signOut()
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
