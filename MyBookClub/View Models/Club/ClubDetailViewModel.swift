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
    private(set) var nextMeeting: Meeting?
    var isJoining = false
    var isScheduling = false
    var error: AppError?
    var showCapacityReachedAlert = false

    // MARK: - Derived

    var isMember: Bool    { membershipStatus == .active }
    var isOrganiser: Bool { myRole == .organiser }

    // True when a cap is set and active member count has reached it.
    func isAtCapacity(club: Club) -> Bool {
        guard club.memberCap > 0, let count = club.memberCount else { return false }
        return count >= club.memberCap
    }

    // MARK: - Load

    private(set) var members: [AppUser] = []

    func loadMembers(clubId: UUID) async {
        do {
            members = try await SupabaseService.shared.fetchClubMembers(clubId: clubId)
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func loadMembership(clubId: UUID) async {
        do {
            membershipStatus = try await SupabaseService.shared.membershipStatus(clubId: clubId)
            myRole           = try await SupabaseService.shared.myRole(clubId: clubId)
        } catch { }
    }

    func loadNextMeeting(clubId: UUID) async {
        do {
            let meetings = try await SupabaseService.shared.fetchMeetings(clubId: clubId)
            nextMeeting = meetings.first { $0.scheduledAt > .now }
        } catch { }
    }

    func reloadClub(clubId: UUID) async -> Club? {
        do {
            return try await SupabaseService.shared.fetchClub(id: clubId)
        } catch {
            self.error = AppError(underlying: error)
            return nil
        }
    }

    // MARK: - Join

    func joinClub(club: Club) async {
        isJoining = true
        defer { isJoining = false }
        do {
            try await SupabaseService.shared.joinClub(
                clubId: club.id,
                isPublic: club.isPublic,
                memberCap: club.memberCap
            )
            membershipStatus = club.isPublic ? .active : .pending

            if club.isPublic, club.memberCap > 0,
               let count = club.memberCount {
                // count is pre-join; add 1 for the member who just joined
                if count + 1 >= club.memberCap {
                    showCapacityReachedAlert = true
                }
            }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Schedule meeting (organiser only)

    func scheduleMeeting(
        clubId: UUID,
        title: String,
        scheduledAt: Date,
        fromChapter: Int?,
        toChapter: Int?,
        chapterTitles: [String]?,
        address: String?,
        isFinal: Bool
    ) async {
        isScheduling = true
        defer { isScheduling = false }
        do {
            let meeting = try await SupabaseService.shared.createMeeting(
                clubId: clubId,
                title: title,
                scheduledAt: scheduledAt,
                fromChapter: fromChapter,
                toChapter: toChapter,
                chapterTitles: chapterTitles,
                notes: nil,
                address: address,
                isFinal: isFinal
            )
            nextMeeting = meeting
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Leave

    func leaveClub(clubId: UUID) async {
        do {
            try await SupabaseService.shared.leaveClub(clubId: clubId)
            membershipStatus = nil
            myRole = nil
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
