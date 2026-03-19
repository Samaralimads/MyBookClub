//
//  ClubCard.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI

struct ClubCard: View {
    let club: Club
    var userRole: MemberRole? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Cover image
            AsyncImage(url: club.coverImageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.purpleTint
                    .overlay {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 36))
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipped()

            VStack(alignment: .leading, spacing: Spacing.xs) {

                // Row 1: Name + role badge
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Text(club.name)
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let role = userRole {
                        Text(role == .organiser ? "ORGANIZER" : "MEMBER")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentSubtle)
                            .clipShape(.rect(cornerRadius: CornerRadius.button))
                    }
                }

                // Row 2: Genre
                if let firstGenre = club.genreTags.first,
                   let genre = Genre(rawValue: firstGenre) {
                    Text(genre.label)
                        .font(.appCaption.weight(.semibold))
                        .foregroundStyle(.accent)
                }

                // Row 3: Members + recurring day
                HStack(spacing: Spacing.lg) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 11))
                        Text("\(club.memberCount ?? 0)")
                            .font(.appCaption)
                    }
                    .foregroundStyle(.inkSecondary)

                    if let day = club.recurringDay {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(day)
                                .font(.appCaption)
                        }
                        .foregroundStyle(.inkSecondary)
                    }
                }

                // Row 4: Currently reading
//                if let book = club.currentBook {
//                    HStack(spacing: 4) {
//                        Text("Reading:")
//                            .font(.appCaption.weight(.semibold))
//                            .foregroundStyle(.inkPrimary)
//                        Text(book.title)
//                            .font(.appCaption)
//                            .foregroundStyle(.inkSecondary)
//                            .lineLimit(1)
//                    }
//                }
            }
            .padding(Spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    LazyVStack(spacing: Spacing.md) {
        ClubCard(
            club: Club(
                id: UUID(),
                name: "The Page Turners",
                description: "A cosy group of literary fiction lovers.",
                genreTags: ["literary-fiction"],
                cityLabel: "Le Marais, Paris",
                isPublic: true,
                memberCap: 15,
                createdAt: .now,
                memberCount: 12,
                distanceMeters: 800
            ),
            userRole: nil
        )
    }
    .padding(Spacing.lg)
}
