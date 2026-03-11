//
//  ClubBooktab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubBookTab: View {
    let club: Club
    let isMember: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let book = club.currentBook {
                Text("Reading Now")
                    .font(.appHeadline)
                    .foregroundColor(.inkPrimary)

                HStack(spacing: Spacing.lg) {
                    AsyncImage(url: book.displayCoverURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Color.purpleTint
                    }
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge))
                    .shadow(color: .black.opacity(0.1), radius: 4)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(book.title)
                            .font(.appHeadline)
                            .foregroundColor(.inkPrimary)
                        Text(book.author)
                            .font(.appBody)
                            .foregroundColor(.inkSecondary)
                    }
                }
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 36))
                        .foregroundColor(.inkTertiary)
                    Text("No book selected yet")
                        .font(.appBody)
                        .foregroundColor(.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxl)
            }
        }
        .padding(.bottom, Spacing.xxl)
    }
}
