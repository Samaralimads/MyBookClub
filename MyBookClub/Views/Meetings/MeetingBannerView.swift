//
//  MeetingBannerView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 17/03/2026.
//

import SwiftUI

// The organiser sees an edit (pencil) button; members see the card as-is.
struct MeetingBannerView: View {
    let meeting: Meeting
    let isOrganiser: Bool
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upcoming Meeting")
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                    Text(meeting.title)
                        .font(.appBody)
                        .foregroundStyle(.inkSecondary)
                }
                Spacer()
                if isOrganiser {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundStyle(.inkSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                meetingRow(
                    icon: "calendar",
                    text: meeting.scheduledAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
                )
                meetingRow(
                    icon: "clock",
                    text: meeting.scheduledAt.formatted(.dateTime.hour().minute())
                )
                if let address = meeting.address, !address.isEmpty {
                    meetingRow(icon: "mappin.and.ellipse", text: address)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
    }

    private func meetingRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.purpleTint)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.accent)
            }
            Text(text)
                .font(.appBody.weight(.semibold))
                .foregroundStyle(.inkPrimary)
        }
    }
}
