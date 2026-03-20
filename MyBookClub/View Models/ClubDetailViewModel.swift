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
    
    // MARK: - Derived
    
    var isMember: Bool    { membershipStatus == .active }
    var isOrganiser: Bool { myRole == .organiser }
    
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
    
    // MARK: - Load Club's latest state
    
    func reloadClub(clubId: UUID) async -> Club? {
        do {
            return try await SupabaseService.shared.fetchClub(id: clubId)
        } catch {
            self.error = AppError(underlying: error)
            return nil
        }
    }
    
    // MARK: - Join
    
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
