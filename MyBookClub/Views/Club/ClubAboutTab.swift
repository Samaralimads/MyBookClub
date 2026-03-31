//
//  ClubAboutTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubAboutTab: View {
    let club: Club
    let vm: ClubDetailViewModel
    let onSchedule: (String, Date, Int?, Int?, [String]?, String?, Bool) -> Void
    let onUpdateMeeting: (String, Date, Int?, Int?, [String]?, String?, Bool) -> Void

    @State private var showPlanMeeting = false
    @State private var showEditMeeting = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            meetingSection
            descriptionSection
            membersSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.xxl)
        .sheet(isPresented: $showPlanMeeting) {
            PlanMeetingSheet(
                existingMeeting: nil,
                isScheduling: vm.isScheduling,
                onSchedule: { title, date, from, to, titles, address, isFinal in
                    onSchedule(title, date, from, to, titles, address, isFinal)
                    showPlanMeeting = false
                },
                onDismiss: { showPlanMeeting = false }
            )
        }
        .sheet(isPresented: $showEditMeeting) {
            PlanMeetingSheet(
                existingMeeting: vm.nextMeeting,
                isScheduling: vm.isScheduling,
                onSchedule: { title, date, from, to, titles, address, isFinal in
                    onUpdateMeeting(title, date, from, to, titles, address, isFinal)
                    showEditMeeting = false
                },
                onDismiss: { showEditMeeting = false }
            )
        }
    }

    // MARK: - Meeting section

    @ViewBuilder
    private var meetingSection: some View {
        if let meeting = vm.nextMeeting, vm.isMember || vm.isOrganiser {
            MeetingBannerView(
                meeting: meeting,
                isOrganiser: vm.isOrganiser,
                rsvpStatus: vm.rsvpStatus,
                rsvpCounts: vm.rsvpCounts,
                rsvpMembers: vm.rsvpMembers,
                onRSVP: { status in
                    Task {
                        await vm.updateRSVP(
                            status: status,
                            meetingId: meeting.id,
                            clubId: club.id
                        )
                    }
                },
                onEdit: { showEditMeeting = true }
            )
        } else if vm.isOrganiser {
            Button { showPlanMeeting = true } label: {
                Label("Plan Next Meeting", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Description section

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = club.description {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Description")
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                Text(description)
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Members section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Members")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
            MemberAvatarStack(count: club.memberCount ?? 0, members: vm.members)
        }
    }
}

// MARK: - Member Avatar Stack

struct MemberAvatarStack: View {
    let count: Int
    var members: [AppUser] = []

    private let visibleCount = 5
    private let size: CGFloat = 40
    private let overlap: CGFloat = 12

    var body: some View {
        let shown = min(visibleCount, count)
        let hasExtra = count > visibleCount

        HStack(spacing: -(overlap)) {
            ForEach(0..<shown, id: \.self) { i in
                avatarView(for: i)
            }
            if hasExtra {
                Circle()
                    .fill(Color.border)
                    .overlay {
                        Text("+\(count - visibleCount)")
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(.inkSecondary)
                    }
                    .overlay { Circle().stroke(Color.background, lineWidth: 2) }
                    .frame(width: size, height: size)
            }
        }
    }

    @ViewBuilder
    private func avatarView(for index: Int) -> some View {
        Group {
            if let avatarURL = members.indices.contains(index) ? members[index].avatarURL : nil,
               let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay { Circle().stroke(Color.background, lineWidth: 2) }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.purpleTint)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(.accent)
                    .font(.system(size: 16))
            }
    }
}
