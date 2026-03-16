//
//  ClubDetailViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 13/03/2026.
//

import Foundation

@Observable
final class ClubDetailViewModel {

    // MARK: - State

    private(set) var membershipStatus: MemberStatus?
    private(set) var myRole: MemberRole?
    var isJoining = false
    var error: AppError?

    // MARK: - Derived

    var isMember: Bool    { membershipStatus == .active }
    var isOrganiser: Bool { myRole == .organiser }

    // MARK: - Actions

    func loadMembership(clubId: UUID) async {
        do {
            membershipStatus = try await SupabaseService.shared.membershipStatus(clubId: clubId)
            myRole           = try await SupabaseService.shared.myRole(clubId: clubId)
        } catch { }
    }

    func joinClub(clubId: UUID, isPublic: Bool) async {
        isJoining = true
        defer { isJoining = false }
        do {
            try await SupabaseService.shared.joinClub(clubId: clubId, isPublic: isPublic)
            membershipStatus = isPublic ? .active : .pending
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
