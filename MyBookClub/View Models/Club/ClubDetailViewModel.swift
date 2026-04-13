//
//  ClubDetailViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 13/03/2026.
//

import Foundation

@Observable
final class ClubDetailViewModel {

    // MARK: - Loading

    private(set) var isLoading = true

    // MARK: - Membership

    private(set) var membershipStatus: MemberStatus?
    private(set) var myRole: MemberRole?
    private(set) var members: [AppUser] = []
    private(set) var pendingMembers: [AppUser] = []

    // MARK: - Meeting

    private(set) var nextMeeting: Meeting?
    var isScheduling = false

    // MARK: - RSVP

    private(set) var rsvpStatus: RSVPStatus? = nil
    private(set) var rsvpCounts: RSVPCounts = RSVPCounts(goingCount: 0, notGoingCount: 0)
    private(set) var rsvpMembers: [RSVPMember] = []

    // MARK: - Join

    var isJoining = false

    // MARK: - Alerts

    var error: AppError?
    var showCapacityReachedAlert = false

    // MARK: - Derived

    var isMember: Bool    { membershipStatus == .active }
    var isOrganiser: Bool { myRole == .organiser }

    func isAtCapacity(club: Club) -> Bool {
        guard club.memberCap > 0, let count = club.memberCount else { return false }
        return count >= club.memberCap
    }

    // MARK: - Initial load

    /// Single entry point called from ClubDetailView.task.
    /// Runs all fetches concurrently and sets isLoading = false when done.
    func loadAll(clubId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        // Load membership first so isOrganiser is set before fetching pending members
        await loadMembership(clubId: clubId)

        // Then load the rest in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadMembers(clubId: clubId) }
            group.addTask { await self.loadNextMeeting(clubId: clubId) }
            group.addTask { await self.loadPendingMembers(clubId: clubId) }
        }
    }

    func reloadClub(clubId: UUID) async -> Club? {
        do {
            return try await SupabaseService.shared.fetchClub(id: clubId)
        } catch {
            self.error = AppError(underlying: error)
            return nil
        }
    }

    // MARK: - Private loaders

    private func loadMembership(clubId: UUID) async {
        do {
            membershipStatus = try await SupabaseService.shared.membershipStatus(clubId: clubId)
            myRole           = try await SupabaseService.shared.myRole(clubId: clubId)
        } catch { }
    }

    private func loadMembers(clubId: UUID) async {
        do {
            members = try await SupabaseService.shared.fetchClubMembers(clubId: clubId)
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    private func loadPendingMembers(clubId: UUID) async {
        guard isOrganiser else { return }
        do {
            pendingMembers = try await SupabaseService.shared.fetchPendingMembers(clubId: clubId)
        } catch {
            // Ignore — non-organisers will be blocked by RLS
        }
    }

    private func loadNextMeeting(clubId: UUID) async {
        do {
            let meetings = try await SupabaseService.shared.fetchMeetings(clubId: clubId)
            nextMeeting = meetings.first { $0.scheduledAt > .now }
            if let meeting = nextMeeting {
                await loadRSVPData(meetingId: meeting.id)
            }
        } catch { }
    }

    // MARK: - RSVP

    private func loadRSVPData(meetingId: UUID) async {
        do {
            async let myRSVPTask  = SupabaseService.shared.fetchMyRSVP(meetingId: meetingId)
            async let countsTask  = SupabaseService.shared.fetchRSVPCounts(meetingId: meetingId)
            async let membersTask = SupabaseService.shared.fetchRSVPMembers(meetingId: meetingId)
            let (rsvp, counts, list) = try await (myRSVPTask, countsTask, membersTask)
            rsvpStatus  = rsvp?.status
            rsvpCounts  = counts
            rsvpMembers = list
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func updateRSVP(status: RSVPStatus, meetingId: UUID, clubId: UUID) async {
        rsvpStatus = status
        do {
            try await SupabaseService.shared.upsertRSVP(
                meetingId: meetingId,
                clubId: clubId,
                status: status
            )
            rsvpCounts  = try await SupabaseService.shared.fetchRSVPCounts(meetingId: meetingId)
            rsvpMembers = try await SupabaseService.shared.fetchRSVPMembers(meetingId: meetingId)
        } catch {
            self.error = AppError(underlying: error)
            await loadRSVPData(meetingId: meetingId)
        }
    }

    // MARK: - Schedule meeting (organiser)

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
            rsvpStatus  = nil
            rsvpCounts  = RSVPCounts(goingCount: 0, notGoingCount: 0)
            rsvpMembers = []
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Update meeting (organiser)

    func updateMeeting(
        clubId: UUID,
        title: String,
        scheduledAt: Date,
        fromChapter: Int?,
        toChapter: Int?,
        chapterTitles: [String]?,
        address: String?,
        isFinal: Bool
    ) async {
        guard let existing = nextMeeting else {
            await scheduleMeeting(
                clubId: clubId, title: title, scheduledAt: scheduledAt,
                fromChapter: fromChapter, toChapter: toChapter,
                chapterTitles: chapterTitles, address: address, isFinal: isFinal
            )
            return
        }
        isScheduling = true
        defer { isScheduling = false }
        do {
            nextMeeting = try await SupabaseService.shared.updateMeeting(
                meetingId: existing.id,
                title: title,
                scheduledAt: scheduledAt,
                fromChapter: fromChapter,
                toChapter: toChapter,
                chapterTitles: chapterTitles,
                address: address,
                isFinal: isFinal
            )
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Approve / Reject join requests

    func approveMember(clubId: UUID, user: AppUser) async {
        do {
            try await SupabaseService.shared.approveMember(clubId: clubId, userId: user.id)
            pendingMembers.removeAll { $0.id == user.id }
            members.append(user)
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func rejectMember(clubId: UUID, user: AppUser) async {
        do {
            try await SupabaseService.shared.rejectMember(clubId: clubId, userId: user.id)
            pendingMembers.removeAll { $0.id == user.id }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Join club

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
               let count = club.memberCount, count + 1 >= club.memberCap {
                showCapacityReachedAlert = true
            }
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Club URL

    func shareURL(for clubId: UUID) -> URL {
        URL(string: "https://mybookclub.app/club/\(clubId.uuidString)")
            ?? URL(string: "https://mybookclub.app")!
    }

    // MARK: - Apply club update (cache-bust cover + reload)

    func applyClubUpdate(_ updated: Club) async -> Club {
        var busted = cacheBust(updated)
        if let fresh = await reloadClub(clubId: updated.id) {
            busted = cacheBust(fresh)
        }
        return busted
    }

    private func cacheBust(_ club: Club) -> Club {
        var result = club
        if let url = club.coverImageURL {
            let base = url.components(separatedBy: "?").first ?? url
            let timestamp = Int(Date().timeIntervalSince1970)
            result.coverImageURL = "\(base)?t=\(timestamp)"
        }
        return result
    }

    // MARK: - Leave club

    func leaveClub(clubId: UUID) async {
        do {
            try await SupabaseService.shared.leaveClub(clubId: clubId)
            membershipStatus = nil
            myRole           = nil
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
