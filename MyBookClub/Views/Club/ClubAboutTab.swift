//
//  ClubAboutTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubAboutTab: View {
    let club: Club

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {

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
                MemberAvatarStack(count: club.memberCount ?? 0)
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
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Genres")
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                HStack(spacing: Spacing.sm) {
                    ForEach(club.genreTags.compactMap { Genre(rawValue: $0) }, id: \.rawValue) { genre in
                        Text(genre.label)
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(.accent)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.accentSubtle)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.bottom, Spacing.xxl)
    }
}

// MARK: - Member Avatar Stack

struct MemberAvatarStack: View {
    let count: Int
    private let visibleCount = 5
    private let size: CGFloat = 40
    private let overlap: CGFloat = 12

    var body: some View {
        let shown = min(visibleCount, count)
        let hasExtra = count > visibleCount
        let totalItems = shown + (hasExtra ? 1 : 0)
        let totalWidth = CGFloat(totalItems) * (size - overlap) + overlap

        ZStack(alignment: .leading) {
            ForEach(0..<shown, id: \.self) { i in
                Circle()
                    .fill(Color.purpleTint)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 16))
                    )
                    .overlay(Circle().stroke(Color.background, lineWidth: 2))
                    .frame(width: size, height: size)
                    .offset(x: CGFloat(i) * (size - overlap))
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
                    .offset(x: CGFloat(shown) * (size - overlap))
            }
        }
        .frame(width: totalWidth, height: size)
    }
}
