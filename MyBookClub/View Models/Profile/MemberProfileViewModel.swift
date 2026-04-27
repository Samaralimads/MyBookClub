//
//  MemberProfileViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 27/04/2026.
//

import SwiftUI

@Observable
final class MemberProfileViewModel {
    var user: AppUser?
    var isLoading = false
    var error: Error?

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await SupabaseService.shared.fetchUser(id: userId)
        } catch {
            self.error = error
        }
    }
}
