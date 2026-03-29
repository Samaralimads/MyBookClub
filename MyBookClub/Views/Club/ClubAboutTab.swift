//
//  ClubAboutTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubAboutTab: View {
    let club: Club
    let isOrganiser: Bool
    let isMember: Bool
    let nextMeeting: Meeting?
    let isScheduling: Bool
    let members: [AppUser]
    let onSchedule: (String, Date, Int?, Int?, [String]?, String?, Bool) -> Void
    
    @State private var showPlanMeeting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            
            //banner OR button
            Group {
                if let meeting = nextMeeting, (isMember || isOrganiser) {
                    MeetingBannerView(meeting: meeting)
                } else if isOrganiser {
                    Button {
                        showPlanMeeting = true
                    } label: {
                        Label(
                            "Plan Next Meeting",
                            systemImage: "calendar.badge.plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            
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
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Members")
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                MemberAvatarStack(count: club.memberCount ?? 0, members: members)
            }
            
            if let day = club.recurringDay {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Meeting Schedule")
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.accent)
                        Text(day.capitalized)
                            .font(.appBody)
                            .foregroundStyle(.inkSecondary)
                        if let time = club.recurringTime {
                            Text("· \(time)")
                                .font(.appBody)
                                .foregroundStyle(.inkSecondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.xxl)
        .sheet(isPresented: $showPlanMeeting) {
            PlanMeetingSheet(
                existingMeeting: nextMeeting,
                isScheduling: isScheduling,
                onSchedule: { title, date, from, to, titles, address, isFinal in
                    onSchedule(title, date, from, to, titles, address, isFinal)
                    showPlanMeeting = false
                },
                onDismiss: { showPlanMeeting = false }
            )
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
                    .overlay(
                        Text("+\(count - visibleCount)")
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(.inkSecondary)
                    )
                    .overlay(Circle().stroke(Color.background, lineWidth: 2))
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
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.background, lineWidth: 2))
    }
    
    private var placeholder: some View {
        Circle()
            .fill(Color.purpleTint)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundStyle(.accent)
                    .font(.system(size: 16))
            )
    }
}
