//
//  MeetingBannerView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 17/03/2026.
//

import SwiftUI

struct MeetingBannerView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upcoming Meeting")
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                    Text(meeting.title)
                        .font(.appBody)
                        .foregroundStyle(.inkSecondary)
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
